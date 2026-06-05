#!/bin/bash
# DND Mode - toggles Do Not Disturb and hides hyprpanel bar

DND_STATE="$HOME/.cache/dnd_mode_state"

if [ -f "$DND_STATE" ]; then
  # Turn OFF DND
  rm -f "$DND_STATE"
  hyprpanel toggleWindow bar-0
  hyprpanel dnd
  /home/linuxbrew/.linuxbrew/bin/tmux set -g status on
else
  # Turn ON DND
  touch "$DND_STATE"
  hyprpanel toggleWindow bar-0
  hyprpanel dnd
  /home/linuxbrew/.linuxbrew/bin/tmux set -g status off
fi
