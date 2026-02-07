#!/bin/bash
# Temperature monitor widget for hyprpanel
# Shows icon and blinks when CPU temp is too high

TEMP_HIGH_FILE="/tmp/.temp_high_$USER"
GENERATE_SCRIPT="$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh"
THRESHOLD=80  # Celsius

get_max_temp() {
    local max=0
    
    # Try sensors first (more accurate)
    if command -v sensors &>/dev/null; then
        max=$(sensors 2>/dev/null | grep -oP 'Core.*?\+\K[0-9]+' | sort -rn | head -1)
    fi
    
    # Fallback to thermal zones
    if [[ -z "$max" || "$max" -eq 0 ]]; then
        for zone in /sys/class/thermal/thermal_zone*/temp; do
            if [[ -f "$zone" ]]; then
                temp=$(($(cat "$zone") / 1000))
                [[ $temp -gt $max ]] && max=$temp
            fi
        done
    fi
    
    echo "$max"
}

temp=$(get_max_temp)

# Test mode: temp-status.sh test (shows real temp but forces widget visible)
TEST_MODE=false
if [[ "${1:-}" == "test" ]]; then
    TEST_MODE=true
fi

if [[ "$temp" -ge "$THRESHOLD" ]] || [[ "$TEST_MODE" == "true" ]]; then
    if [[ ! -f "$TEMP_HIGH_FILE" ]]; then
        touch "$TEMP_HIGH_FILE"
        "$GENERATE_SCRIPT"
    fi
    echo "{\"text\": \"󰈸 ${temp}°\", \"tooltip\": \"CPU Temperature: ${temp}°C (HIGH!)\"}"
else
    if [[ -f "$TEMP_HIGH_FILE" ]]; then
        rm -f "$TEMP_HIGH_FILE"
        "$GENERATE_SCRIPT"
    fi
    # Return empty to hide widget when temp is normal
    echo '{"text": "", "tooltip": ""}'
fi
