#!/usr/bin/env bash
SCRATCH_CLASS="random-scratch"

WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$SCRATCH_CLASS\")" 2>/dev/null)

if [ -z "$WINDOW" ] || [ "$WINDOW" = "null" ]; then
    foot --app-id=random-scratch &>/dev/null &
    exit 0
fi

ADDR=$(echo "$WINDOW" | jq -r '.address')
WS=$(echo "$WINDOW" | jq -r '.workspace.id')

if [ "$WS" = "99" ]; then
    hyprctl dispatch movetoworkspacesilent "e+0,address:$ADDR"
    hyprctl dispatch focuswindow "address:$ADDR"
else
    hyprctl dispatch movetoworkspacesilent "99,address:$ADDR"
fi
