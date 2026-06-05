#!/usr/bin/env bash
# Live overview of all AOE worker sessions: one row per `aoe_*` tmux session
# with its Claude state (working/input/done/idle) and GitLab pipeline icon.
# Reuses the exact signals + palette from tmux-session-list, rendered as
# truecolor ANSI for a standalone pane/popup.
#
#   swarm-dashboard.sh watch        redraw every 2s (matches status-bar cadence)
#   swarm-dashboard.sh once         render a single frame
#   swarm-dashboard.sh review <id>  per-perspective ✓/◌ for a review run
#   swarm-dashboard.sh pipeline     current repo's pipeline status line
set -uo pipefail

AOE="$(command -v aoe || echo /home/linuxbrew/.linuxbrew/bin/aoe)"
now() { date +%s; }

# Truecolor helpers (palette matches tmux-session-list).
c() { printf '\033[38;2;%sm' "$1"; }     # set fg from "R;G;B"
RST=$'\033[0m'; BOLD=$'\033[1m'
GREEN='166;227;161'; RED='243;139;168'; YEL='249;226;175'
CYAN='137;220;235'; ORANGE='250;179;135'; GREY='157;152;159'

# Claude state for a tmux session name (mirrors tmux-session-list session_status).
session_status() {
  local f="/tmp/.claude-tmux-status-${1}" raw ts
  [ -f "$f" ] || return
  raw="$(cat "$f" 2>/dev/null)"
  case "$raw" in
    input) printf 'input' ;;
    done)  printf 'done' ;;
    working:*)
      ts="${raw#working:}"
      [ $(( $(now) - ts )) -lt 300 ] && printf 'working'
      ;;
  esac
}

# Pipeline status word for a tmux session (via its pane path -> poller cache).
pipeline_status() {
  local s="$1" path key cache
  path="$(tmux display-message -p -t "${s}:" '#{pane_current_path}' 2>/dev/null)"
  [ -z "$path" ] && return
  key="$(printf '%s' "$path" | md5sum | cut -c1-16)"
  cache="/tmp/.claude-tmux-pipeline-${key}"
  [ -f "$cache" ] && cat "$cache" 2>/dev/null
}

pipe_cell() {
  case "$1" in
    running)            printf '%s⟳ running%s'  "$(c $CYAN)"  "$RST" ;;
    success)            printf '%s✓ success%s'  "$(c $GREEN)" "$RST" ;;
    failed)             printf '%s✗ failed%s'   "$(c $RED)"   "$RST" ;;
    pending|created|preparing|scheduled|waiting_for_resource)
                        printf '%s◌ pending%s'  "$(c $YEL)"   "$RST" ;;
    *) printf ' ' ;;
  esac
}

state_cell() {
  case "$1" in
    working) printf '%s⠿ working%s' "$(c $ORANGE)" "$RST" ;;
    input)   printf '%s● input%s'   "$(c $RED)"    "$RST" ;;
    done)    printf '%s✓ done%s'    "$(c $GREEN)"  "$RST" ;;
    *)       printf '%s· idle%s'    "$(c $GREY)"   "$RST" ;;
  esac
}

render() {
  printf '%s%-26s %-14s %-12s%s\n' "$BOLD" "SESSION" "STATE" "PIPELINE" "$RST"
  local s label st pl any=0
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    any=1
    label="${s#aoe_}"; label="$(printf '%s' "$label" | sed -E 's/_[0-9a-f]+$//')"
    st="$(session_status "$s")"
    pl="$(pipeline_status "$s")"
    printf '%-26s %b %b\n' "$label" "$(printf '%-22b' "$(state_cell "$st")")" "$(pipe_cell "$pl")"
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^aoe_' | sort)
  [ "$any" = 0 ] && printf '%s(no aoe_ worker sessions)%s\n' "$(c $GREY)" "$RST"
  # Aggregate footer from aoe.
  local agg
  agg="$("$AOE" status --json 2>/dev/null \
        | jq -r '"running:\(.running)  waiting:\(.waiting)  idle:\(.idle)  error:\(.error)  total:\(.total)"' 2>/dev/null)"
  [ -n "$agg" ] && printf '\n%s%s%s\n' "$(c $GREY)" "$agg" "$RST"
}

render_review() {
  local id="${1:?review id}" dir="/tmp/aoe-review-${1}" p f
  printf '%sreview %s%s\n\n' "$BOLD" "$id" "$RST"
  for p in security perf consistency factual; do
    f="$dir/$p.md"
    if [ -s "$f" ]; then printf '  %s✓%s %s\n' "$(c $GREEN)" "$RST" "$p"
    else                 printf '  %s◌%s %s\n' "$(c $GREY)"  "$RST" "$p"; fi
  done
}

render_pipeline() {
  local key cache st
  key="$(printf '%s' "$PWD" | md5sum | cut -c1-16)"
  cache="/tmp/.claude-tmux-pipeline-${key}"
  st="$( [ -f "$cache" ] && cat "$cache" 2>/dev/null )"
  printf '%spipeline%s  %b\n' "$BOLD" "$RST" "$(pipe_cell "${st:-none}")"
}

case "${1:-once}" in
  watch)    while true; do clear; render; sleep 2; done ;;
  once)     render ;;
  review)   shift; render_review "${1:-}" ;;
  pipeline) render_pipeline ;;
  *) echo "usage: swarm-dashboard.sh {watch|once|review <id>|pipeline}" >&2; exit 1 ;;
esac
