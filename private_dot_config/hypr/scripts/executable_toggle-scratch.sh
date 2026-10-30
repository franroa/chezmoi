#!/usr/bin/env bash
source "$HOME/.config/hypr/scripts/hypr-lua.sh"
SCRATCH_CLASS="random-scratch"

WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$SCRATCH_CLASS\")" 2>/dev/null)

if [ -z "$WINDOW" ] || [ "$WINDOW" = "null" ]; then
    foot --app-id=random-scratch &>/dev/null &
    exit 0
fi

ADDR=$(echo "$WINDOW" | jq -r '.address')
WS=$(echo "$WINDOW" | jq -r '.workspace.id')

if [ "$WS" = "99" ]; then
    hl_move_window_silent "$(hl_current_ws)" "address:$ADDR"
    hl_focus_window "address:$ADDR"
else
    hl_move_window_silent "99" "address:$ADDR"
fi
