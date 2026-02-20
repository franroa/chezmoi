#!/bin/bash
# Open Google Calendar in a floating Chrome window

# Get current window IDs before launching
before=$(swaymsg -t get_tree | jq -r '.. | select(.pid?) | .id' | sort)

google-chrome --new-window "https://calendar.google.com/calendar/u/0/r/day" &

# Wait for new window to appear
for i in {1..30}; do
    sleep 0.2
    after=$(swaymsg -t get_tree | jq -r '.. | select(.pid?) | .id' | sort)
    new_id=$(comm -13 <(echo "$before") <(echo "$after") | head -1)
    if [ -n "$new_id" ]; then
        swaymsg "[con_id=$new_id] floating enable, resize set 1600 1000, move position center, focus"
        exit 0
    fi
done
