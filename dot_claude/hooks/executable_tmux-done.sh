#!/usr/bin/env bash
# Sets "done" state (green blink) in tmux status bar when Claude finishes the job.
# Called from the Stop hook.
[ -z "$TMUX" ] && exit 0

session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
[[ "$session" =~ -T2$ ]] && session="${session%-T2}"
[ -z "$session" ] && exit 0

printf 'done' > "/tmp/.claude-tmux-status-${session}"
tmux refresh-client -S 2>/dev/null
