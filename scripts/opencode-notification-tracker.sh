#!/bin/bash
# OpenCode notification tracker for hyprpanel
# Uses shared notification-tracker-lib.sh

NOTIF_STATE_DIR="/tmp/opencode_notifications_$USER"
NOTIF_COUNTER_FILE="/tmp/.opencode_unread_$USER"
NOTIF_APP_NAME="OpenCode"

source /home/froa/.config/hypr/scripts/notification-tracker-lib.sh

case "${1:-status}" in
    add)
        notif_add "$2" "$3" "$4"
        ;;
    remove)
        notif_remove "$2"
        ;;
    clear)
        notif_clear
        ;;
    count)
        notif_get_count
        ;;
    sources)
        notif_show_sources
        ;;
    status|*)
        notif_status
        ;;
esac
