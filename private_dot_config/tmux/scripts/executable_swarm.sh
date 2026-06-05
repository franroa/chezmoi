#!/usr/bin/env bash
# Ticket swarm: launch N independent AOE worker sessions (each its own git
# worktree + Claude) in the CURRENT repo, track them in a registry, and tear
# them all down later. The dashboard (swarm-dashboard.sh) shows live state.
#
#   swarm.sh spawn "<entry>,<entry>,..."  one worker per comma-separated entry
#   swarm.sh interactive                  prompt for the entries (run in a popup)
#   swarm.sh teardown                     remove every worker in the registry
#   swarm.sh list                         print the registry
#
# Each entry is:  "<type>-<TICKET> <free description>"
#   "feat-P0004-111 this is my session name"
#     -> session/worktree : P0004-111-this-is-my-session-name
#        local branch      : feat/P0004-111-this-is-my-session-name
#        remote branch     : feat/P0004-111-<jira-summary-slug>  (Jira; desc fallback)
# type ∈ feat|fix|poc|chore|refactor (anything before the first '-' of token 1).
#
# Registry: /tmp/aoe-swarm/registry  — lines: <aoe_id>\t<tmux_session>\t<name>
# The tmux session is captured by diffing `tmux ls` before/after spawn, because
# `aoe list --json` does not expose it and the Claude status files are keyed by
# the tmux session name (/tmp/.claude-tmux-status-<tmux_session>).
set -uo pipefail

AOE="$(command -v aoe || echo /home/linuxbrew/.linuxbrew/bin/aoe)"
REG_DIR=/tmp/aoe-swarm
REG="$REG_DIR/registry"

for bin in aoe jq tmux; do
  command -v "$bin" >/dev/null 2>&1 || { echo "❌ missing dependency: $bin" >&2; exit 1; }
done

aoe_sessions() { tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^aoe_' || true; }

# Live state of a worker, read from the Claude status file (same signal the
# status bar uses).  working|input|done|idle
session_state() {
  local f="/tmp/.claude-tmux-status-${1}" raw ts
  [ -f "$f" ] || { echo idle; return; }
  raw="$(cat "$f" 2>/dev/null)"
  case "$raw" in
    input) echo input ;;
    done)  echo done ;;
    working:*) ts="${raw#working:}"; [ $(( $(date +%s) - ts )) -lt 300 ] && echo working || echo idle ;;
    *) echo idle ;;
  esac
}

# Resolve a registry row by aoe-id OR by session name -> "id\ttmux\tname".
reg_row() {
  [ -f "$REG" ] || return 1
  awk -F'\t' -v q="$1" '$1==q || $3==q {print; exit}' "$REG"
}

# kebab-case a free-text string: lowercase, drop junk, collapse spaces/hyphens.
slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 -]//g; s/[ -]+/-/g; s/^-+//; s/-+$//'; }

# Jira summary for a ticket id, or empty (graceful fallback to the typed desc).
jira_summary() {
  local tok="${JIRA_TOKEN:-${JIRA_API_TOKEN:-}}"
  [ -n "${JIRA_BASE_URL:-}" ] && [ -n "${JIRA_EMAIL:-}" ] && [ -n "$tok" ] || return 0
  curl -s --max-time 8 -u "${JIRA_EMAIL}:${tok}" -H 'Accept: application/json' \
       "${JIRA_BASE_URL}/rest/api/2/issue/${1}" 2>/dev/null \
    | jq -r '.fields.summary // empty' 2>/dev/null
}

# Spawn one worker from a structured entry:  "<type>-<TICKET> <free description>"
#   e.g.  "feat-P0004-111 this is my session name"
#     type        = feat
#     ticket       = P0004-111
#     session/dir  = P0004-111-this-is-my-session-name      (local name you typed)
#     local branch = feat/P0004-111-this-is-my-session-name
#     remote branch= feat/P0004-111-<jira-summary-slug>     (Jira; desc as fallback)
# derive "<entry>" -> echoes TAB:  type \t ticket \t session \t local_branch \t remote_branch
# (hits Jira for the remote slug; falls back to the typed description). No spawning.
derive() {
  local entry first type ticket desc desc_slug session summary remote_slug
  entry="$(printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  [ -z "$entry" ] && return 1
  first="${entry%%[[:space:]]*}"                 # feat-P0004-111
  desc="${entry#"$first"}"                        # rest (the description)
  desc="$(printf '%s' "$desc" | sed -E 's/^[[:space:]]+//')"
  type="${first%%-*}"                             # feat
  ticket="${first#*-}"                            # P0004-111
  if [ "$type" = "$first" ] || [ -z "$ticket" ]; then
    echo "swarm: cannot parse '<type>-<ticket>' from '$first' — skipping" >&2; return 1
  fi
  ticket="$(printf '%s' "$ticket" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')"
  desc_slug="$(slug "$desc")"
  session="$ticket"; [ -n "$desc_slug" ] && session="${ticket}-${desc_slug}"
  summary="$(jira_summary "$ticket")"
  remote_slug="$(slug "$summary")"; [ -z "$remote_slug" ] && remote_slug="$desc_slug"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$type" "$ticket" "$session" "${type}/${session}" "${type}/${ticket}-${remote_slug}"
}

parse() {  # dry-run: show derivation for every entry, no spawning
  local entry type ticket session local_branch remote_branch
  IFS=',' read -ra entries <<< "$1"
  for entry in "${entries[@]}"; do
    IFS=$'\t' read -r type ticket session local_branch remote_branch < <(derive "$entry") || continue
    [ -z "${session:-}" ] && continue
    printf '→ %s\n   local : %s\n   remote: %s\n' "$session" "$local_branch" "$remote_branch"
  done
}

spawn_entry() {
  local type ticket session local_branch remote_branch
  IFS=$'\t' read -r type ticket session local_branch remote_branch < <(derive "$1") || return 1
  [ -z "${session:-}" ] && return 1

  echo "→ ${session}"
  echo "   local branch : ${local_branch}"
  echo "   remote branch: ${remote_branch}"

  local before after new id wt
  before="$(aoe_sessions)"
  if ! "$AOE" add . -w "$local_branch" -b -t "$session" -l >/dev/null 2>&1; then
    echo "   ✗ aoe add failed" >&2; return 1
  fi
  id="$("$AOE" list --json 2>/dev/null | jq -r 'sort_by(.created_at)|last|.id')"
  wt="$("$AOE" list --json 2>/dev/null | jq -r 'sort_by(.created_at)|last|.path')"
  # Map the short local branch to the long remote branch (aoen's trick), and
  # let a bare `git push` send to that differently-named upstream.
  if [ -n "$wt" ] && [ -d "$wt" ]; then
    git -C "$wt" config "branch.${local_branch}.remote" origin
    git -C "$wt" config "branch.${local_branch}.merge" "refs/heads/${remote_branch}"
    git -C "$wt" config push.default upstream
  fi
  # Find the worker's tmux session by diffing before/after.
  new=""
  for _ in $(seq 1 20); do
    after="$(aoe_sessions)"
    new="$(comm -13 <(printf '%s\n' "$before" | sort -u) <(printf '%s\n' "$after" | sort -u) \
           | grep '^aoe_' | head -1)"
    [ -n "$new" ] && break
    sleep 0.5
  done
  printf '%s\t%s\t%s\n' "${id:-?}" "${new:-?}" "$session" >> "$REG"
  # Seed the agent once its TUI is up.  Tight seed = less wandering = fewer
  # tokens: SWARM_SEED is a template ({ticket} is substituted); SWARM_SEED_SUFFIX
  # appends scope guardrails. Defaults to the ticket skill.
  if [ -n "$id" ]; then
    local seed="${SWARM_SEED:-/working-on-ticket {ticket}}"
    seed="${seed//\{ticket\}/$ticket}"
    [ -n "${SWARM_SEED_SUFFIX:-}" ] && seed="${seed} ${SWARM_SEED_SUFFIX}"
    sleep "${SWARM_SEED_DELAY:-3}"
    "$AOE" send "$id" "$seed" >/dev/null 2>&1 || true
  fi
  echo "   ✓ id=${id} tmux=${new}"
}

# spawn "<entry>,<entry>,..."  — entries are "<type>-<TICKET> <description>"
spawn() {
  mkdir -p "$REG_DIR"; touch "$REG"
  local entry
  IFS=',' read -ra entries <<< "$1"
  for entry in "${entries[@]}"; do
    spawn_entry "$entry" || true
  done
  echo "registry: $REG"
}

interactive() {
  local csv
  echo "Format per entry:  <type>-<TICKET> <description>   (type ∈ feat|fix|poc|chore|refactor)"
  echo "Example: feat-P0004-111 this is my session name, fix-Z0323-81 this is another name"
  read -rp "swarm entries: " csv
  [ -z "${csv:-}" ] && { echo "nothing to spawn"; return 0; }
  spawn "$csv"
  echo; read -rp "Press enter to close…" _
}

teardown() {
  [ -f "$REG" ] || { echo "no swarm registry at $REG"; return 0; }
  local id tmux name
  while IFS=$'\t' read -r id tmux name; do
    [ -z "${id:-}" ] || [ "$id" = "?" ] && continue
    echo "removing ${name} (${id})…"
    "$AOE" remove "$id" --delete-worktree --delete-branch --force >/dev/null 2>&1 \
      || echo "  warn: aoe remove failed for $id" >&2
  done < "$REG"
  rm -f "$REG"
  echo "swarm torn down."
}

# Read a worker's latest output WITHOUT attaching to its session — cheaper than
# opening a client, and lets you (or an orchestrator) pull results back as text.
peek() {  # <id-or-name> [-n N]
  local key="${1:?usage: swarm.sh peek <id|name> [-n N]}" n="${3:-60}" row id
  row="$(reg_row "$key")" || { echo "no such worker: $key" >&2; return 1; }
  id="$(printf '%s' "$row" | cut -f1)"
  [ -z "$id" ] || [ "$id" = "?" ] && { echo "worker has no aoe id" >&2; return 1; }
  "$AOE" session capture "$id" -n "$n" --strip-ansi
}

# Interactive peek: show the registry, prompt for a worker, page its output.
# Used by the tmux menu / keybinding (which has no id to pass).
peek_i() {
  list; echo
  local k
  read -rp "peek which worker (id or name, empty=cancel): " k
  [ -z "${k:-}" ] && return 0
  peek "$k" -n "${PEEK_LINES:-200}" | ${PAGER:-less -R}
}

# Reap only the workers that have finished (status file == done). Keeps the
# dashboard and `aoe status` cheap; long-running workers stay untouched.
reap_done() {
  [ -f "$REG" ] || { echo "(empty swarm)"; return 0; }
  local id tmux name kept=0 reaped=0 tmpf
  tmpf="$(mktemp)"
  while IFS=$'\t' read -r id tmux name; do
    [ -z "${id:-}" ] && continue
    if [ "$id" != "?" ] && [ "$(session_state "$tmux")" = "done" ]; then
      echo "reaping done: ${name} (${id})"
      "$AOE" remove "$id" --delete-worktree --delete-branch --force >/dev/null 2>&1 \
        || echo "  warn: aoe remove failed for $id" >&2
      reaped=$((reaped+1))
    else
      printf '%s\t%s\t%s\n' "$id" "$tmux" "$name" >> "$tmpf"
      kept=$((kept+1))
    fi
  done < "$REG"
  mv -f "$tmpf" "$REG"
  echo "reaped ${reaped} done worker(s); ${kept} still active."
}

list() {
  [ -f "$REG" ] || { echo "(empty swarm)"; return 0; }
  printf '%-18s %-30s %-24s %s\n' ID TMUX NAME STATE
  while IFS=$'\t' read -r id tmux name; do
    printf '%-18s %-30s %-24s %s\n' "$id" "$tmux" "$name" "$(session_state "$tmux")"
  done < "$REG"
}

case "${1:-}" in
  spawn)       shift; spawn "${1:-}" ;;
  parse)       shift; parse "${1:-}" ;;
  interactive) interactive ;;
  peek)        shift; peek "$@" ;;
  peek-i)      peek_i ;;
  reap-done)   reap_done ;;
  teardown)    teardown ;;
  list)        list ;;
  *) echo "usage: swarm.sh {spawn \"<entry>,...\"|parse|interactive|peek <id|name> [-n N]|reap-done|teardown|list}" >&2; exit 1 ;;
esac
