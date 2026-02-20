#!/bin/bash
# Click and focus the newly opened window

# Start listening for new window events in background
timeout 5 swaymsg -m -t subscribe '["window"]' | while read -r event; do
    change=$(echo "$event" | jq -r '.change')
    if [ "$change" = "new" ]; then
        con_id=$(echo "$event" | jq -r '.container.id')
        sleep 0.1
        swaymsg "[con_id=$con_id]" focus
        exit 0
    fi
done &

listener_pid=$!

# Minimal delay just to ensure listener is ready
sleep 0.02

# Perform a plain left click immediately
ydotool click --delay 0 1

# Wait for listener to finish or timeout
wait $listener_pid 2>/dev/null
