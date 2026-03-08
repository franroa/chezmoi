#!/bin/bash
# Daemon that adds dynamic keybindings when notification panel is visible
# and removes them when it closes

NOTIF_NAMESPACE="notifications-window"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"
SCRIPT_DIR="/home/froa/.config/hypr/scripts"
PANEL_WAS_OPEN=false

add_notification_binds() {
    # Read letter maps and create binds for each letter
    for letter in {a..z}; do
        # Check if letter exists in either map
        if grep -q "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null || \
           grep -q "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null; then
            # Add bind with SUPER modifier - only works when panel is open
            hyprctl keyword bind "SUPER, ${letter}, exec, ${SCRIPT_DIR}/notif-trigger-direct.sh letter ${letter}" 2>/dev/null
        fi
    done
    echo "Added notification binds at $(date)"
}

remove_notification_binds() {
    # Remove all notification letter binds by setting empty exec
    for letter in {a..z}; do
        hyprctl keyword bind "SUPER, ${letter}, exec, " 2>/dev/null
    done
    echo "Removed notification binds at $(date)"
}

check_panel() {
    hyprctl layers 2>/dev/null | grep -q "namespace: ${NOTIF_NAMESPACE}"
}

while true; do
    if check_panel; then
        if [ "$PANEL_WAS_OPEN" = false ]; then
            echo "Notification panel opened - adding dynamic binds"
            add_notification_binds
            PANEL_WAS_OPEN=true
        fi
    else
        if [ "$PANEL_WAS_OPEN" = true ]; then
            echo "Notification panel closed - removing dynamic binds"
            remove_notification_binds
            PANEL_WAS_OPEN=false
        fi
    fi
    
    sleep 0.3
done
