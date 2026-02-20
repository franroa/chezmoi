#!/bin/bash
swaymsg -t subscribe -m '["window"]' | while read -r event; do
    change=$(echo "$event" | jq -r '.change')
    if [ "$change" = "focus" ]; then
        focused_id=$(echo "$event" | jq -r '.container.id')
        swaymsg "[con_id=$focused_id] opacity 1"
        swaymsg "[con_id!=$focused_id] opacity 0.5"
    fi
done
