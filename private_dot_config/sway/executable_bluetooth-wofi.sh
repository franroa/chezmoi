#!/bin/bash
# Bluetooth device selector using wofi and bluetoothctl
# Requires: bluez, wofi, notify-send

set -euo pipefail

notify() {
    notify-send -t 3000 "Bluetooth" "$1"
}

get_paired_devices() {
    bluetoothctl devices Paired 2>/dev/null | while read -r _ mac name; do
        local connected=""
        if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
            connected=" 󰄬"
        fi
        echo "󰂯 $name ($mac)$connected"
    done
}

get_available_devices() {
    bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
        if ! bluetoothctl devices Paired 2>/dev/null | grep -q "$mac"; then
            echo "󰂲 $name ($mac)"
        fi
    done
}

connect_device() {
    local mac="$1"
    local name="$2"
    
    if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
        notify "Disconnecting from $name..."
        if bluetoothctl disconnect "$mac" &>/dev/null; then
            notify "Disconnected from $name"
        else
            notify "Failed to disconnect from $name"
        fi
    else
        notify "Connecting to $name..."
        if bluetoothctl connect "$mac" &>/dev/null; then
            notify "Connected to $name"
        else
            notify "Failed to connect to $name"
        fi
    fi
}

pair_device() {
    local mac="$1"
    local name="$2"
    
    notify "Pairing with $name..."
    if bluetoothctl pair "$mac" &>/dev/null; then
        bluetoothctl trust "$mac" &>/dev/null
        notify "Paired with $name"
        connect_device "$mac" "$name"
    else
        notify "Failed to pair with $name"
    fi
}

toggle_bluetooth() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power off
        notify "Bluetooth disabled"
    else
        bluetoothctl power on
        notify "Bluetooth enabled"
    fi
}

scan_devices() {
    notify "Scanning for devices..."
    bluetoothctl --timeout 5 scan on &>/dev/null || true
}

main() {
    if ! bluetoothctl show | grep -q "Powered: yes"; then
        local action
        action=$(echo -e "󰂲 Enable Bluetooth\n󰜺 Cancel" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Bluetooth is disabled")
        case "$action" in
            *"Enable"*)
                bluetoothctl power on
                notify "Bluetooth enabled"
                sleep 1
                ;;
            *)
                exit 0
                ;;
        esac
    fi

    local paired available menu
    paired=$(get_paired_devices)
    available=$(get_available_devices)

    menu=""
    [[ -n "$paired" ]] && menu+="$paired\n"
    [[ -n "$available" ]] && menu+="$available\n"
    menu+="───────────────\n"
    menu+="󰑓 Scan for devices\n"
    menu+="󰂲 Toggle Bluetooth\n"
    menu+="󰒓 Open blueman-manager"

    local selected
    selected=$(echo -e "$menu" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Bluetooth" --insensitive)
    [[ -z "$selected" ]] && exit 0

    case "$selected" in
        *"Scan"*)
            scan_devices
            exec "$0"
            ;;
        *"Toggle"*)
            toggle_bluetooth
            ;;
        *"blueman"*)
            blueman-manager &
            ;;
        "───"*)
            exit 0
            ;;
        󰂯*)
            local mac name
            mac=$(echo "$selected" | grep -oE '[A-F0-9:]{17}')
            name=$(echo "$selected" | sed 's/󰂯 //;s/ ([A-F0-9:]\{17\}).*//')
            connect_device "$mac" "$name"
            ;;
        󰂲*)
            local mac name
            mac=$(echo "$selected" | grep -oE '[A-F0-9:]{17}')
            name=$(echo "$selected" | sed 's/󰂲 //;s/ ([A-F0-9:]\{17\}).*//')
            pair_device "$mac" "$name"
            ;;
    esac
}

main "$@"
