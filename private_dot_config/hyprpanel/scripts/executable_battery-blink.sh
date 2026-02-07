#!/usr/bin/env bash
# Battery low detection - sets flag file for generate-modules-scss.sh

BATTERY_LOW_FILE="/tmp/.battery_low_$USER"
GENERATE_SCRIPT="$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh"

check_battery() {
    local battery_path=""
    
    for path in /sys/class/power_supply/BAT*/uevent; do
        if [ -f "$path" ]; then
            battery_path="$path"
            break
        fi
    done
    
    if [ -z "$battery_path" ]; then
        return 1
    fi
    
    local status=$(grep "POWER_SUPPLY_STATUS=" "$battery_path" | cut -d= -f2)
    local capacity=$(grep "POWER_SUPPLY_CAPACITY=" "$battery_path" | cut -d= -f2)
    
    if [ "$status" != "Charging" ] && [ "$status" != "Full" ] && [ "$capacity" -lt 20 ]; then
        return 0
    fi
    
    return 1
}

while true; do
    if check_battery; then
        if [ ! -f "$BATTERY_LOW_FILE" ]; then
            touch "$BATTERY_LOW_FILE"
            "$GENERATE_SCRIPT"
        fi
    else
        if [ -f "$BATTERY_LOW_FILE" ]; then
            rm -f "$BATTERY_LOW_FILE"
            "$GENERATE_SCRIPT"
        fi
    fi
    sleep 5
done
