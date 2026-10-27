#!/bin/bash

CURRENT_TEMP=$(sensors 2>/dev/null | grep "Package id 0:" | awk '{print $4}' | tr -d '+°C')
IDLE_TEMP_FILE="$HOME/.cache/idle_temp"

echo "$CURRENT_TEMP" > "$IDLE_TEMP_FILE"
notify-send -i dialog-information "󱃃 Idle Temp Set" "Baseline set to ${CURRENT_TEMP}°C"
