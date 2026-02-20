#!/bin/bash
# Focus Mode - minimizes distractions
# Toggles Do Not Disturb and hides hyprpanel bar

FOCUS_STATE="$HOME/.cache/focus_mode_state"

toggle_focus() {
    if [ -f "$FOCUS_STATE" ]; then
        # Turn OFF focus mode
        rm -f "$FOCUS_STATE"
        hyprpanel toggleWindow bar-0     # Show panel
        notify-send "Focus Mode" "OFF - Notifications enabled" -t 2000
    else
        # Turn ON focus mode
        touch "$FOCUS_STATE"
        hyprpanel toggleWindow bar-0     # Hide panel
        notify-send "Focus Mode" "ON - Notifications silenced" -t 3000
    fi
}

toggle_focus
