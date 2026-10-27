#!/bin/bash
# Check if notification panel is open
NOTIF_NAMESPACE="notifications-window"

if hyprctl layers 2>/dev/null | grep -q "namespace: ${NOTIF_NAMESPACE}"; then
    # Panel is open - trigger notification
    /home/froa/.config/hypr/scripts/notif-trigger-direct.sh letter "$1"
else
    # Panel is closed - pass through the key (no action)
    exit 0
fi
