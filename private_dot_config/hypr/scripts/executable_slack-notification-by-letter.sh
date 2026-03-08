#!/bin/bash
# Trigger Slack notification action by letter
# Note: Slack notifications come from Slack app, so we can't add letters to the title
# But we can track them and show a menu

TRACKER="/home/froa/.config/hypr/scripts/slack-monitor.sh"
LETTER_MAP="/tmp/.slack_letter_map"

# Get all tracked Slack notifications
if [[ ! -f "/tmp/slack_notifications_$USER" ]] || [[ -z "$(ls -A /tmp/slack_notifications_$USER 2>/dev/null)" ]]; then
    notify-send "Slack" "No active notifications"
    exit 0
fi

# Build menu options from tracked notifications
OPTIONS=""
for notif_file in /tmp/slack_notifications_$USER/*.notif; do
    if [[ -f "$notif_file" ]]; then
        NOTIF_ID=$(basename "$notif_file" .notif)
        SOURCE=$(cat "$notif_file" | cut -d'|' -f1)
        
        # Get a letter for this notification
        LETTER=""
        if [[ -f "$LETTER_MAP" ]]; then
            LETTER=$(grep ":$NOTIF_ID|" "$LETTER_MAP" 2>/dev/null | cut -d: -f1)
        fi
        
        if [[ -n "$LETTER" ]]; then
            OPTIONS="$OPTIONS$LETTER: $SOURCE\n"
        else
            # Just show source without letter
            OPTIONS="$OPTIONS[ ] $SOURCE\n"
        fi
    fi
done

if [[ -z "$OPTIONS" ]]; then
    notify-send "Slack" "No trackable notifications"
    exit 0
fi

# Show rofi menu
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Slack notification:")

if [[ -z "$CHOICE" ]]; then
    exit 0
fi

# For now, just open Slack
~/.config/hypr/scripts/goto-slack.sh
