#!/bin/bash
# Go to workspace 4 (Slack), focus, go to unreads

~/.local/bin/pypr hide "*" 2>/dev/null
hyprctl dispatch workspace 4

slack_addr=$(hyprctl clients -j | jq -r '.[] | select(.class == "Slack") | .address' | head -1)
[[ -z "$slack_addr" ]] && exit 0

hyprctl dispatch focuswindow "address:${slack_addr}"
sleep 0.2
wtype -M ctrl -M shift -k a -m shift -m ctrl
