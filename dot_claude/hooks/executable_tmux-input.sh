#!/usr/bin/env bash
# Sets "input" state (red blink) in tmux status bar when Claude is waiting
# for user input (permission prompt / elicitation). Called from Notification hook.
[ -z "$TMUX" ] && exit 0

session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
[[ "$session" =~ -T2$ ]] && session="${session%-T2}"
[ -z "$session" ] && exit 0

printf 'input' > "/tmp/.claude-tmux-status-${session}"
tmux refresh-client -S 2>/dev/null
