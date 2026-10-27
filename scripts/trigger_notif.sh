#!/bin/bash
LETTER="$1"
MAP_FILE="/tmp/hypr_notif_map"

NOTIF=$(grep "^${LETTER}:" "$MAP_FILE" | head -1)
APP=$(echo "$NOTIF" | cut -d: -f2)

case "$APP" in
    *[Ss]lack*)
        ~/.config/hypr/scripts/goto-slack.sh
        ;;
    *)
        echo "No action for $APP"
        ;;
esac
