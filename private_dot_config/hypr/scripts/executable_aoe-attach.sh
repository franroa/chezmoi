#!/usr/bin/env bash
# Simplified aoe attach script for pyprland scratchpad

CWD=$(cat /tmp/aoe_cwd_target 2>/dev/null)
if [[ -z "$CWD" ]]; then
  CWD=$(cat /tmp/last_nvim_root 2>/dev/null)
fi
if [[ -z "$CWD" ]]; then
  CWD="$HOME"
fi

SESSION_NAME="aoe_$(basename "$CWD")"

# Create session if it doesn't exist
tmux new-session -d -s "$SESSION_NAME" -c "$CWD" 2>/dev/null

# Attach to the session
exec tmux attach-session -t "$SESSION_NAME"
