#!/bin/bash
# WiFi network selector using wofi and nmcli
# Requires: NetworkManager, wofi, notify-send

set -euo pipefail

notify() {
    notify-send -t 3000 "WiFi" "$1"
}

get_current_connection() {
    nmcli -t -f NAME,TYPE connection show --active | grep wireless | cut -d: -f1 || echo ""
}

scan_networks() {
    # Rescan for networks
    nmcli device wifi rescan 2>/dev/null || true
    sleep 1
    
    # List networks with signal strength
    nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE device wifi list | \
        awk -F: '
            $1 != "" {
                signal = $2
                security = ($3 != "" && $3 != "--") ? "󰌾" : "󰌿"
                in_use = ($4 == "*") ? " 󰄬" : ""
                
                # Signal icon based on strength
                if (signal >= 75) icon = "󰤨"
                else if (signal >= 50) icon = "󰤥"
                else if (signal >= 25) icon = "󰤢"
                else icon = "󰤟"
                
                printf "%s %s %s%% %s%s\n", icon, $1, signal, security, in_use
            }
        ' | sort -t'%' -k1 -rn | uniq
}

connect_network() {
    local ssid="$1"
    local current
    current=$(get_current_connection)
    
    # Check if already connected
    if [[ "$current" == "$ssid" ]]; then
        notify "Already connected to $ssid"
        return
    fi
    
    # Check if known network
    if nmcli connection show "$ssid" &>/dev/null; then
        notify "Connecting to $ssid..."
        if nmcli connection up "$ssid" &>/dev/null; then
            notify "Connected to $ssid"
        else
            notify "Failed to connect to $ssid"
        fi
    else
        # New network - ask for password
        local security
        security=$(nmcli -t -f SSID,SECURITY device wifi list | grep "^$ssid:" | head -1 | cut -d: -f2)
        
        if [[ -n "$security" && "$security" != "--" ]]; then
            local password
            password=$(wofi --dmenu --password --prompt "Password for $ssid" --lines 0 --style ~/.config/wofi/active-theme.css)
            [[ -z "$password" ]] && exit 0
            
            notify "Connecting to $ssid..."
            if nmcli device wifi connect "$ssid" password "$password" &>/dev/null; then
                notify "Connected to $ssid"
            else
                notify "Failed to connect to $ssid"
            fi
        else
            notify "Connecting to $ssid..."
            if nmcli device wifi connect "$ssid" &>/dev/null; then
                notify "Connected to $ssid"
            else
                notify "Failed to connect to $ssid"
            fi
        fi
    fi
}

toggle_wifi() {
    local status
    status=$(nmcli radio wifi)
    
    if [[ "$status" == "enabled" ]]; then
        nmcli radio wifi off
        notify "WiFi disabled"
    else
        nmcli radio wifi on
        notify "WiFi enabled"
    fi
}

main() {
    # Check if WiFi is enabled
    local wifi_status
    wifi_status=$(nmcli radio wifi)
    
    if [[ "$wifi_status" != "enabled" ]]; then
        local action
        action=$(echo -e "󰤮 Enable WiFi\n󰜺 Cancel" | wofi --dmenu --prompt "WiFi is disabled" --style ~/.config/wofi/active-theme.css)
        case "$action" in
            *"Enable"*)
                nmcli radio wifi on
                notify "WiFi enabled, scanning..."
                sleep 2
                ;;
            *)
                exit 0
                ;;
        esac
    fi
    
    # Build menu
    local networks
    networks=$(scan_networks)
    
    local menu="$networks"
    menu+="\n───────────────"
    menu+="\n󰑓 Rescan networks"
    menu+="\n󰤮 Disable WiFi"
    menu+="\n󰒓 Network settings"
    
    local current
    current=$(get_current_connection)
    if [[ -n "$current" ]]; then
        menu+="\n󰅗 Disconnect from $current"
    fi
    
    # Show menu
    local selected
    selected=$(echo -e "$menu" | wofi --dmenu --prompt "WiFi Networks" --insensitive --style ~/.config/wofi/active-theme.css)
    [[ -z "$selected" ]] && exit 0
    
    case "$selected" in
        *"Rescan"*)
            notify "Scanning..."
            exec "$0"
            ;;
        *"Disable WiFi"*)
            toggle_wifi
            ;;
        *"Network settings"*)
            nm-connection-editor &
            ;;
        *"Disconnect"*)
            nmcli connection down "$current"
            notify "Disconnected from $current"
            ;;
        "───"*)
            exit 0
            ;;
        *)
            # Extract SSID (second field after icon)
            local ssid
            ssid=$(echo "$selected" | awk '{print $2}')
            connect_network "$ssid"
            ;;
    esac
}

main "$@"
