#!/bin/bash
source "$HOME/.config/hypr/scripts/hypr-lua.sh"
# Toggle pyprland scratchpad and hide Slack special workspace

# Check if Slack special workspace is currently visible on any monitor
if hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name == "special:slack")' >/dev/null 2>&1; then
    hl_toggle_special slack
fi

# Now toggle the requested scratchpad
pypr toggle "$@"
