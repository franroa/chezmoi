#!/bin/bash
# Toggle aoe-cwd foot terminal (show/hide)

AOE_CLASS="aoe-cwd"

# Get window
WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$AOE_CLASS\")" 2>/dev/null)

if [ -z "$WINDOW" ] || [ "$WINDOW" = "null" ]; then
    # Not running - launch it
    foot --app-id=aoe-cwd &>/dev/null &
    exit 0
fi

ADDR=$(echo "$WINDOW" | jq -r '.address')
WS=$(echo "$WINDOW" | jq -r '.workspace.id')

if [ "$WS" = "99" ]; then
    # Hidden on ws 99 - show on ws 1 and focus
    hyprctl dispatch movetoworkspacesilent "1,address:$ADDR"
    hyprctl dispatch focuswindow "address:$ADDR"
else
    # Visible - hide to ws 99 (silent = don't switch focus)
    hyprctl dispatch movetoworkspacesilent "99,address:$ADDR"
fi
