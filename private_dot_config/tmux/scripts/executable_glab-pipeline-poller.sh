#!/usr/bin/env bash
# Background daemon: for every tmux session whose active pane sits in a GitLab
# repo, fetch the current branch's latest pipeline status and cache it so the
# status bar can show an icon cheaply. One instance only (pid-guarded).
#
# Cache file per session path: /tmp/.claude-tmux-pipeline-<key>
#   key = first 16 hex of md5(path)   (must match tmux-session-list)
set -uo pipefail

GLAB="$(command -v glab || echo /home/linuxbrew/.linuxbrew/bin/glab)"
INTERVAL=10
PIDFILE=/tmp/.claude-tmux-pipeline-poller.pid

# glab auth needs GITLAB_TOKEN. This daemon is launched from the status-line
# #() command, which inherits the tmux SERVER's start environment — that often
# predates the 1Password token loader, so the token is missing here even though
# `set-environment -g` put it in the global env for panes. Pull it from there.
if [ -z "${GITLAB_TOKEN:-}" ]; then
  tok="$(tmux show-environment -g GITLAB_TOKEN 2>/dev/null | sed -n 's/^GITLAB_TOKEN=//p')"
  [ -n "$tok" ] && export GITLAB_TOKEN="$tok"
fi

# Single instance.
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
  exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

key_for() { printf '%s' "$1" | md5sum | cut -c1-16; }

# Emit the status of every downstream/child pipeline, recursively.
downstream_statuses() {
  local proj="$1" plid="$2" bridges
  bridges="$("$GLAB" api "projects/${proj}/pipelines/${plid}/bridges?per_page=100" 2>/dev/null)" || return
  printf '%s' "$bridges" | jq -r '
    .[] | select(.downstream_pipeline != null)
    | [(.downstream_pipeline.project_id|tostring),
       (.downstream_pipeline.id|tostring),
       (.downstream_pipeline.status // "")] | @tsv' 2>/dev/null \
  | while IFS=$'\t' read -r dproj did dstatus; do
      [ -z "$did" ] && continue
      printf '%s\n' "$dstatus"
      downstream_statuses "$dproj" "$did"   # recurse into grandchildren
    done
}

# Reduce a newline list of pipeline statuses to one, worst-wins:
#   failed > running > pending > success > (everything else -> none)
# A single broken child therefore breaks the whole.
reduce_status() {
  local fail=0 run=0 pend=0 succ=0 s
  while IFS= read -r s || [ -n "$s" ]; do
    case "$s" in
      failed)                         fail=1 ;;
      running|created|preparing|waiting_for_resource|scheduled) run=1 ;;
      pending)                        pend=1 ;;
      success)                        succ=1 ;;
    esac
  done
  if   [ "$fail" = 1 ]; then printf 'failed'
  elif [ "$run"  = 1 ]; then printf 'running'
  elif [ "$pend" = 1 ]; then printf 'pending'
  elif [ "$succ" = 1 ]; then printf 'success'
  else printf 'none'; fi
}

write_cache() {  # path  status
  local key cache tmp prev marker
  key="$(key_for "$1")"
  cache="/tmp/.claude-tmux-pipeline-${key}"
  marker="/tmp/.claude-tmux-pipeline-finished-${key}"
  prev="$(cat "$cache" 2>/dev/null)"
  # Detect a pipeline that just FINISHED (active -> terminal): drop a marker the
  # status bar blinks pink on, cleared when its session is focused. A fresh run
  # (terminal/none -> active) clears any stale marker so old blinks don't linger.
  case "$prev" in
    running|pending|created|preparing|scheduled|waiting_for_resource)
      case "$2" in success|failed) : > "$marker" ;; esac ;;
  esac
  case "$2" in
    running|pending|created|preparing|scheduled|waiting_for_resource) rm -f "$marker" ;;
  esac
  tmp="${cache}.$$"
  printf '%s' "$2" > "$tmp" && mv -f "$tmp" "$cache"
}

poll_path() {
  local path="$1"
  [ -d "$path" ] || { write_cache "$path" none; return; }
  git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { write_cache "$path" none; return; }

  local remote
  remote="$(git -C "$path" remote get-url origin 2>/dev/null)"
  case "$remote" in
    *gitlab*) ;;
    *) write_cache "$path" none; return ;;
  esac

  local fullpath encoded branch enc_ref top_json top_id top_status status
  fullpath="$(printf '%s' "$remote" | sed -E 's|^ssh://git@[^/]+/||; s|^git@[^:]+:||; s|^https?://[^/]+/||; s|\.git$||')"
  encoded="${fullpath//\//%2F}"
  branch="$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  enc_ref="${branch//\//%2F}"

  local proj_id
  proj_id="$("$GLAB" api "projects/${encoded}" 2>/dev/null | jq -r '.id // empty')"
  top_json="$("$GLAB" api "projects/${encoded}/pipelines?ref=${enc_ref}&per_page=1" 2>/dev/null)"
  top_id="$(printf '%s' "$top_json"     | jq -r '.[0].id     // empty' 2>/dev/null)"
  top_status="$(printf '%s' "$top_json" | jq -r '.[0].status // empty' 2>/dev/null)"

  if [ -z "$top_id" ]; then
    write_cache "$path" none; return
  fi

  # Aggregate top + all downstream child pipelines (a broken child breaks all).
  if [ -n "$proj_id" ]; then
    status="$( { printf '%s\n' "$top_status"; downstream_statuses "$proj_id" "$top_id"; } | reduce_status )"
  else
    status="${top_status:-none}"
  fi
  write_cache "$path" "$status"
}

while :; do
  changed=0
  for s in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
    case "$s" in
      *-T2) continue ;;
      ''|*[!0-9]*) ;;      # keep non-numeric names
      *) continue ;;       # skip purely numeric session names
    esac
    path="$(tmux display-message -p -t "${s}:" '#{pane_current_path}' 2>/dev/null)"
    [ -z "$path" ] && continue
    poll_path "$path"
    changed=1
  done
  [ "$changed" = 1 ] && tmux refresh-client -S 2>/dev/null
  sleep "$INTERVAL"
done
