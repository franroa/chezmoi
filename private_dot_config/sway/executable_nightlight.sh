#!/bin/bash
# Nightlight toggle using gammastep
# Usage: nightlight.sh [toggle|on|off|status|waybar|menu]

CONFIG_FILE="$HOME/.config/gammastep/config.ini"
STATE_FILE="/tmp/nightlight_settings"

is_running() {
    pgrep -x gammastep >/dev/null 2>&1
}

get_current_temp() {
    if [[ -f "$STATE_FILE" ]]; then
        grep "^temp=" "$STATE_FILE" | cut -d= -f2
    else
        echo "4500"
    fi
}

get_current_brightness() {
    if [[ -f "$STATE_FILE" ]]; then
        grep "^brightness=" "$STATE_FILE" | cut -d= -f2
    else
        echo "1.0"
    fi
}

save_settings() {
    local temp="$1"
    local brightness="$2"
    echo "temp=$temp" > "$STATE_FILE"
    echo "brightness=$brightness" >> "$STATE_FILE"
}

start_gammastep() {
    local temp="${1:-$(get_current_temp)}"
    local brightness="${2:-$(get_current_brightness)}"
    pkill -x gammastep 2>/dev/null
    sleep 0.2
    gammastep -O "$temp" -b "$brightness:$brightness" &disown
    save_settings "$temp" "$brightness"
}

enable_nightlight() {
    if ! is_running; then
        start_gammastep
    fi
}

disable_nightlight() {
    pkill -x gammastep 2>/dev/null
}

show_menu() {
    local current_temp=$(get_current_temp)
    local current_brightness=$(get_current_brightness)
    
    local choice=$(echo -e "󰖨 Brightness: $current_brightness\n󰔏 Temperature: ${current_temp}K\n─────────────\n󰃠 Brightness 100%\n󰃟 Brightness 90%\n󰃞 Brightness 80%\n󰃝 Brightness 70%\n─────────────\n󰖙 Warm (3500K)\n󰖨 Default (4500K)\n󰌵 Cool (5500K)\n󱠃 Neutral (6500K)" | wofi --dmenu --style ~/.config/wofi/active-theme.css -p "Night Light" --width 300 --height 400)
    
    case "$choice" in
        "󰃠 Brightness 100%")
            start_gammastep "$current_temp" "1.0"
            ;;
        "󰃟 Brightness 90%")
            start_gammastep "$current_temp" "0.9"
            ;;
        "󰃞 Brightness 80%")
            start_gammastep "$current_temp" "0.8"
            ;;
        "󰃝 Brightness 70%")
            start_gammastep "$current_temp" "0.7"
            ;;
        "󰖙 Warm (3500K)")
            start_gammastep "3500" "$current_brightness"
            ;;
        "󰖨 Default (4500K)")
            start_gammastep "4500" "$current_brightness"
            ;;
        "󰌵 Cool (5500K)")
            start_gammastep "5500" "$current_brightness"
            ;;
        "󱠃 Neutral (6500K)")
            start_gammastep "6500" "$current_brightness"
            ;;
    esac
}

waybar_output() {
    if is_running; then
        local temp=$(get_current_temp)
        local brightness=$(get_current_brightness)
        echo "{\"text\": \"󰛨\", \"tooltip\": \"Night Light: ON\\nTemp: ${temp}K | Brightness: $brightness\\nClick: toggle | Right-click: settings\", \"class\": \"active\", \"alt\": \"active\"}"
    else
        echo '{"text": "󰹐", "tooltip": "Night Light: OFF\nClick: toggle | Right-click: settings", "class": "inactive", "alt": "inactive"}'
    fi
}

case "${1:-toggle}" in
    on|enable)
        enable_nightlight
        ;;
    off|disable)
        disable_nightlight
        ;;
    toggle)
        if is_running; then
            disable_nightlight
        else
            enable_nightlight
        fi
        ;;
    status)
        if is_running; then
            echo "Night Light: ON ($(get_current_temp)K, $(get_current_brightness))"
        else
            echo "Night Light: OFF"
        fi
        ;;
    waybar)
        waybar_output
        ;;
    menu)
        show_menu
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|status|waybar|menu]"
        exit 1
        ;;
esac
