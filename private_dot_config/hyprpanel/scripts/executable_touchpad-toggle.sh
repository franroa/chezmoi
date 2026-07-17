#!/bin/bash
# Touchpad enable/disable toggle for hyprpanel + wlr-which-key

STATE_FILE="/tmp/.touchpad_disabled_$USER"

get_device_name() {
    hyprctl devices -j 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for m in d.get('mice', []):
        if 'touchpad' in m.get('name', '').lower():
            print(m['name'])
            break
except Exception:
    pass
"
}

DEVICE=$(get_device_name)
[[ -z "$DEVICE" ]] && DEVICE="elan0307:00-04f3:3282-touchpad"

is_disabled() {
    [[ -f "$STATE_FILE" ]]
}

disable() {
    hyprctl keyword "device[$DEVICE]:enabled" 0 >/dev/null 2>&1
    touch "$STATE_FILE"
    [[ "$1" != "--silent" ]] && notify-send "Touchpad" "Disabled" -t 1500
}

enable() {
    hyprctl keyword "device[$DEVICE]:enabled" 1 >/dev/null 2>&1
    rm -f "$STATE_FILE"
    [[ "$1" != "--silent" ]] && notify-send "Touchpad" "Enabled" -t 1500
}

case "$1" in
    toggle)
        if is_disabled; then
            enable
        else
            disable
        fi
        ;;
    disable)
        disable "$2"
        ;;
    enable)
        enable "$2"
        ;;
    *)
        if is_disabled; then
            echo '{"text": "", "alt": "disabled", "tooltip": "Touchpad: Disabled (click to enable)"}'
        else
            echo '{"text": "", "alt": "enabled", "tooltip": "Touchpad: Enabled (click to disable)"}'
        fi
        ;;
esac
