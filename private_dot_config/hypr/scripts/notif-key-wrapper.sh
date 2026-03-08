#!/bin/bash
# Wrapper script that checks if notification panel is open before executing command

PANEL_STATE_FILE="/tmp/notif_panel_state_${USER}"

if [[ "$(cat "$PANEL_STATE_FILE" 2>/dev/null)" == "open" ]]; then
    notify-send -r 9999 "Test" "You pressed e!"
else
    exit 0
fi
