#!/bin/bash
# Master-stack layout for sway
# Creates a layout with one master window (left, 60%) and stacked windows (right, 40%)

# Get current workspace number
current_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused == true) | .name')

# Get all window IDs on current workspace (recursively find actual windows with app_id or window class)
windows=$(swaymsg -t get_tree | jq -r --arg ws "$current_ws" '
    recurse(.nodes[], .floating_nodes[]?) |
    select(.type == "workspace" and .name == $ws) |
    .. | select(.app_id? != null or .window? != null) | select(.pid? != null) | .id
' 2>/dev/null | sort -u)

window_count=$(echo "$windows" | wc -w)

if [ "$window_count" -lt 2 ]; then
    notify-send "Master-Stack" "Need at least 2 windows (found $window_count)"
    exit 0
fi

# Get the focused window (will be master)
master_id=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true and .pid? != null) | .id')

# First, flatten all windows - move them all to workspace root
for win_id in $windows; do
    swaymsg "[con_id=$win_id] move to workspace $current_ws"
done

# Focus master
swaymsg "[con_id=$master_id] focus"
swaymsg "splith"

# Move all other windows to the right and stack them
first=true
for win_id in $windows; do
    if [ "$win_id" != "$master_id" ]; then
        if $first; then
            swaymsg "[con_id=$win_id] move right"
            swaymsg "[con_id=$win_id] layout stacking"
            first=false
        else
            swaymsg "[con_id=$win_id] move to mark _stack"
        fi
        swaymsg "[con_id=$win_id] mark --add _stack"
    fi
done

# Unmark and resize master to 60%
swaymsg "[con_mark=_stack]" unmark _stack
swaymsg "[con_id=$master_id] focus"
swaymsg "resize set width 60 ppt"

notify-send -t 2000 "Master-Stack" "Layout applied ($window_count windows)"
