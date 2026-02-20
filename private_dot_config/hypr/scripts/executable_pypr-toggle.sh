#!/bin/bash
# Toggle pyprland scratchpad and hide Slack special workspace

# Check if Slack special workspace is currently visible on any monitor
if hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name == "special:slack")' >/dev/null 2>&1; then
    hyprctl dispatch togglespecialworkspace slack
fi

# Now toggle the requested scratchpad
pypr toggle "$@"
