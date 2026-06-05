#!/bin/bash
exec 2>/dev/null

FOOT_APP_ID="aoe-cwd"

# Check if foot window exists
FOOT_WINDOW=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$FOOT_APP_ID\") | .address" | head -1)

if [ -n "$FOOT_WINDOW" ]; then
    # Move to hidden workspace 99
    hyprctl dispatch movetoworkspacesilent "99,address:$FOOT_WINDOW"
fi
