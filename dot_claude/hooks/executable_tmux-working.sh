#!/usr/bin/env bash
# Sets "working" state in tmux status bar when Claude is using a tool.
# Called asynchronously from PreToolUse hook.
[ -z "$TMUX" ] && exit 0

session=$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}' 2>/dev/null)
[[ "$session" =~ -T2$ ]] && session="${session%-T2}"
[ -z "$session" ] && exit 0

printf 'working:%s' "$(date +%s)" > "/tmp/.claude-tmux-status-${session}"
for c in $(tmux list-clients -F "#{client_tty}" 2>/dev/null); do tmux refresh-client -t "$c" -S 2>/dev/null; done
