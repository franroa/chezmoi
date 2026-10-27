#!/bin/bash
# DND Mode - toggles Do Not Disturb and hides hyprpanel bar

DND_STATE="$HOME/.cache/dnd_mode_state"

if [ -f "$DND_STATE" ]; then
    # Turn OFF DND
    rm -f "$DND_STATE"
    astal -i hyprpanel -t bar-0 2>/dev/null
else
    # Turn ON DND
    touch "$DND_STATE"
    astal -i hyprpanel -t bar-0 2>/dev/null
fi
