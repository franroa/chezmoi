#!/bin/bash
# Slack notifications for HyprPanel

SCRIPT="/home/froa/.config/hypr/scripts/slack-notifications.sh"

case "${1:-}" in
    open)
        $SCRIPT open
        ;;
    mark-read)
        $SCRIPT mark-read
        ;;
    *)
        result=$($SCRIPT waybar 2>/dev/null)
        if [[ -z "$result" ]]; then
            echo '{"text": "", "alt": "error"}'
            exit 0
        fi
        
        text=$(echo "$result" | jq -r '.text // "󰒱"')
        tooltip=$(echo "$result" | jq -r '.tooltip // "Slack"')
        class=$(echo "$result" | jq -r '.class // "no-messages"')
        
        # Extract count from text (e.g., "󰒱 5" -> 5)
        count=$(echo "$text" | grep -oE '[0-9]+' || echo "0")
        
        if [[ "$class" == "has-unread" ]]; then
            alt="unread"
        else
            alt="none"
        fi
        
        # Hide count if 0
        if [[ "$count" == "0" ]]; then
            echo "{\"text\": \"\", \"alt\": \"$alt\", \"tooltip\": \"$tooltip\"}"
        else
            echo "{\"text\": \"$count\", \"alt\": \"$alt\", \"tooltip\": \"$tooltip\"}"
        fi
        ;;
esac
