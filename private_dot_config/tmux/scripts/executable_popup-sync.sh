#!/usr/bin/env bash
# Make a window's popups take the cluster color of its active pane.
#   popup-sync.sh [<window-or-pane-target>]   (default: the current pane)
# popup-style doesn't expand formats, so it is set per window; the #{@kube_color}
# lookup below resolves active pane (kubie ctx) -> window -> session (kube-switch.sh).
w=$(tmux display -p -t "${1:-${TMUX_PANE:-}}" '#{window_id}') || exit 0
color=$(tmux display -p -t "$w" '#{@kube_color}')
if [ -n "$color" ]; then
  tmux set-option -w -t "$w" popup-style "bg=$color"
  tmux set-option -w -t "$w" popup-border-style "bg=$color"
else
  tmux set-option -wu -t "$w" popup-style
  tmux set-option -wu -t "$w" popup-border-style
fi
