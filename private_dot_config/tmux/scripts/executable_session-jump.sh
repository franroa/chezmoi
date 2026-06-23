#!/usr/bin/env bash

# Jump to a session by its status-bar letter (a, b, c, …).
# Letters are assigned positionally by tmux-session-list in render order, so
# letter -> index -> session reuses session-menu.sh's index resolver exactly.

letter="$1"
[ -z "$letter" ] && exit 0

letter="${letter,,}"                       # normalise to lowercase
case "$letter" in [a-z]) ;; *) exit 0 ;; esac

idx=$(( $(printf '%d' "'$letter") - 97 ))  # 'a' -> 0, 'b' -> 1, …

exec "$(dirname "$0")/session-menu.sh" "$idx"
