#!/bin/bash

# Get current CPU package temperature
CURRENT_TEMP=$(sensors 2>/dev/null | grep "Package id 0:" | awk '{print $4}' | tr -d '+°C')

# Idle temperature baseline (adjust based on your system)
IDLE_TEMP_FILE="$HOME/.cache/idle_temp"

# If no idle temp recorded, use a default or prompt to set it
if [[ -f "$IDLE_TEMP_FILE" ]]; then
    IDLE_TEMP=$(cat "$IDLE_TEMP_FILE")
else
    IDLE_TEMP="45"  # Default idle temp estimate
fi

# Calculate difference
DIFF=$(echo "$CURRENT_TEMP - $IDLE_TEMP" | bc)

# Determine status icon based on temp
if (( $(echo "$CURRENT_TEMP < 50" | bc -l) )); then
    ICON="󱃃"  # Cool
    STATUS="Cool"
elif (( $(echo "$CURRENT_TEMP < 70" | bc -l) )); then
    ICON="󰔏"  # Normal
    STATUS="Normal"
elif (( $(echo "$CURRENT_TEMP < 85" | bc -l) )); then
    ICON="󰸁"  # Warm
    STATUS="Warm"
else
    ICON="󰈸"  # Hot
    STATUS="Hot!"
fi

notify-send -i dialog-information "$ICON CPU Temperature" \
    "Current: ${CURRENT_TEMP}°C ($STATUS)
Idle baseline: ${IDLE_TEMP}°C
Difference: +${DIFF}°C"
