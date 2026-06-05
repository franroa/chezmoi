#!/bin/bash
# Go to workspace 4 (Slack), focus, go to unreads

~/.local/bin/pypr hide "*" 2>/dev/null
hyprctl dispatch workspace 4
sleep 0.15

slack_addr=$(hyprctl clients -j | jq -r '.[] | select(.class == "slack") | .address' | head -1)
[[ -z "$slack_addr" ]] && exit 0

hyprctl dispatch focuswindow "address:${slack_addr}"

# Wait until Slack actually holds keyboard focus (up to 2s)
for i in {1..20}; do
    active=$(hyprctl activewindow -j | jq -r '.class // ""')
    [[ "$active" == "slack" ]] && break
    sleep 0.1
done
sleep 0.2  # let Electron settle after focus transfer

ydotool key --delay 0 ctrl+shift+a
