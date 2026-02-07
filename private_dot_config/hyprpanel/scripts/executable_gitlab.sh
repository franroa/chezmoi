#!/bin/bash
# GitLab notifications for HyprPanel

SCRIPT="/home/froa/.config/hypr/scripts/gitlab-notifications.sh"

case "${1:-}" in
    open)
        $SCRIPT open
        ;;
    show)
        $SCRIPT show
        ;;
    mark-read)
        $SCRIPT mark-read
        ;;
    *)
        result=$(timeout 2 $SCRIPT waybar 2>/dev/null)
        if [[ -z "$result" ]]; then
            echo '{"text": "", "alt": "none", "tooltip": "GitLab"}'
            exit 0
        fi
        
        text=$(echo "$result" | jq -r '.text // "󰮠"')
        tooltip=$(echo "$result" | jq -r '.tooltip // "GitLab"')
        class=$(echo "$result" | jq -r '.class // "no-comments"')
        
        # Extract count from text (e.g., "󰮠 5" -> 5)
        count=$(echo "$text" | grep -oE '[0-9]+' || echo "0")
        
        if [[ "$class" == "has-comments" ]]; then
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
