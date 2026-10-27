#!/bin/bash
LETTER="$1"
MAP_FILE="/tmp/hypr_notif_map"

if [ -f "$MAP_FILE" ]; then
    result=$(grep "^${LETTER}:" "$MAP_FILE" | tail -1 | cut -d: -f3-)
    if [ -n "$result" ]; then
        echo "$result"
    fi
fi
