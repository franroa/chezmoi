#!/usr/bin/env bash
# Toggle the morning-digest scratchpad (show/hide), modeled on toggle-jira.sh.
# Opens a floating foot window showing the last-sent digest + today's Google
# Calendar agenda (digest-window.sh). Bound to Alt+4 and to the "Open" button on
# the morning-digest notification.
SCRATCH_CLASS="digest-scratch"

WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$SCRATCH_CLASS\")" 2>/dev/null)

if [ -z "$WINDOW" ] || [ "$WINDOW" = "null" ]; then
    # Not running - launch it (digest-window.sh renders then drops to a shell).
    foot --app-id="$SCRATCH_CLASS" /home/froa/.config/hypr/scripts/digest-window.sh &>/dev/null &
    exit 0
fi

ADDR=$(echo "$WINDOW" | jq -r '.address')
WS=$(echo "$WINDOW" | jq -r '.workspace.id')

if [ "$WS" = "99" ]; then
    # Hidden on ws 99 - bring to current workspace and focus.
    hyprctl dispatch movetoworkspacesilent "e+0,address:$ADDR"
    hyprctl dispatch focuswindow "address:$ADDR"
else
    # Visible - hide to ws 99.
    hyprctl dispatch movetoworkspacesilent "99,address:$ADDR"
fi
