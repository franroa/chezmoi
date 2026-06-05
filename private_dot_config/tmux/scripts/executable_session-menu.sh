#!/usr/bin/env bash

# Resolve a status-line click to a session and focus it.
# tmux passes the clicked range index via $1 (mouse_status_range).
# Index order MUST match tmux-session-list's render loop (same filter, same
# `tmux list-sessions` ordering).

idx="$1"
[ -z "$idx" ] && exit 0

all_sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

# Rebuild the visible-session list in render order
declare -a sessions
for s in $all_sessions; do
  [[ "$s" == *-T2 ]] && continue
  [[ "$s" =~ ^[0-9]+$ ]] && continue
  sessions+=("$s")
done

target="${sessions[$idx]}"
[ -z "$target" ] && exit 0

tmux switch-client -t "$target"
tmux refresh-client -S
