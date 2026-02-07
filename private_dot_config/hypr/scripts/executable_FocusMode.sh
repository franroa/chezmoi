#!/bin/bash
# Focus Mode - minimizes distractions
# Toggles Do Not Disturb and shows status

FOCUS_STATE="$HOME/.cache/focus_mode_state"

toggle_focus() {
    if [ -f "$FOCUS_STATE" ]; then
        # Turn OFF focus mode
        rm -f "$FOCUS_STATE"
        swaync-client -d  # Disable DND (show notifications)
        notify-send "Focus Mode" "OFF - Notifications enabled" -t 2000
        exit 0
    else
        # Turn ON focus mode
        touch "$FOCUS_STATE"
        swaync-client -D  # Enable DND (hide notifications)
        notify-send "Focus Mode" "ON - Notifications silenced" -t 3000
        exit 0
    fi
}

toggle_focus
