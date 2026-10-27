#!/bin/bash

MAP_FILE="/tmp/hypr_notif_map"

# Unbind everything currently in the file
if [ -s "$MAP_FILE" ]; then
    while IFS=':' read -r letter app summary; do
        if [ -n "$letter" ]; then
            hyprctl keyword unbind , "$letter"
        fi
    done <"$MAP_FILE"
fi

# Clear the map file so you start fresh for the next batch
>"$MAP_FILE"

# notify-send -t 2000 "Vimium Binds" "Keyboard restored."
