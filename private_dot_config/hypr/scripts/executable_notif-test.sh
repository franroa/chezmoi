#!/bin/bash
# Only show notification when panel is open, otherwise do nothing

check_panel() {
    hyprctl layers 2>/dev/null | grep -q "namespace: notificationsmenu"
}

if check_panel; then
    notify-send "Test" "Panel is open - e pressed!"
fi
