#!/bin/bash
# VPN Toggle Script for Waybar
# Supports OpenVPN via systemd

VPN_SERVICE="openvpn.service"

get_status() {
    if systemctl is-active --quiet "$VPN_SERVICE"; then
        echo '{"text": "󰦝", "tooltip": "VPN: Connected", "class": "connected"}'
    else
        echo '{"text": "󰦞", "tooltip": "VPN: Disconnected", "class": "disconnected"}'
    fi
}

toggle() {
    if systemctl is-active --quiet "$VPN_SERVICE"; then
        sudo systemctl stop "$VPN_SERVICE"
        notify-send -u normal -i network-vpn "VPN" "Disconnected"
    else
        sudo systemctl start "$VPN_SERVICE"
        notify-send -u normal -i network-vpn "VPN" "Connected"
    fi
}

case "$1" in
    status|"")
        get_status
        ;;
    toggle)
        toggle
        ;;
    *)
        echo "Usage: $0 {status|toggle}"
        exit 1
        ;;
esac
