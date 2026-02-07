#!/usr/bin/env bash
# Battery low alert script for hyprpanel
# Add to startup: exec-once = ~/.config/hyprpanel/scripts/battery-alert.sh

LOW_BATTERY_FILE="/tmp/.low_battery_${USER}"
NOTIFIED_FILE="/tmp/.battery_notified_${USER}"

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
        if [ ! -f "$LOW_BATTERY_FILE" ]; then
            touch "$LOW_BATTERY_FILE"
            notify-send "🔋 Low Battery" "Battery is below 20%! Please charge your laptop." -u critical -t 30000
        fi
    else
        rm -f "$LOW_BATTERY_FILE"
    fi
    sleep 30
done
