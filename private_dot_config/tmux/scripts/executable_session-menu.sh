#!/usr/bin/env bash

# Resolve a status-line click to a session and focus it.
# tmux passes the clicked range index via $1 (mouse_status_range).
# Index order MUST match tmux-session-list's render loop (same filter, same
# `tmux list-sessions` ordering).

idx="${1#s}"            # tmux-session-list prefixes the range value with "s"
# switch (left click) | kill = CLOSE tmux session only (right click) |
# remove = CLOSE + `aoe remove` across all profiles (ctrl-right click)
action="${2:-switch}"
[ -z "$idx" ] && exit 0

# Order by creation time (matches tmux-session-list): new sessions append last
# so letter/click indices stay stable.
all_sessions=$(tmux list-sessions -F '#{session_created}	#{session_name}' 2>/dev/null | sort -s -n -k1,1 | cut -f2-)

# Rebuild the visible-session list in render order
declare -a sessions
for s in $all_sessions; do
  [[ "$s" == *-T2 ]] && continue
  [[ "$s" =~ ^[0-9]+$ ]] && continue
  sessions+=("$s")
done

target="${sessions[$idx]}"
[ -z "$target" ] && exit 0

if [ "$action" = "kill" ]; then
  # Right click: CLOSE the tmux session only — leave the AOE record alive.
  "$(dirname "$0")/session-picker.sh" --kill "$target"
  tmux refresh-client -S
  exit 0
fi

if [ "$action" = "remove" ]; then
  # Ctrl-right click: CLOSE + remove the backing AOE session (searches profiles).
  "$(dirname "$0")/session-picker.sh" --remove "$target"
  tmux refresh-client -S
  exit 0
fi

tmux switch-client -t "$target"
tmux refresh-client -S
