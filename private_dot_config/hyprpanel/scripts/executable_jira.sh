#!/bin/bash
# Jira notifications for HyprPanel

SCRIPT="/home/froa/.config/hypr/scripts/jira-notifications.sh"

case "${1:-}" in
    open)
        $SCRIPT open
        ;;
    show)
        $SCRIPT show
        ;;
    *)
        result=$(timeout 2 $SCRIPT waybar 2>/dev/null)
        if [[ -z "$result" ]]; then
            echo '{"text": "", "alt": "none", "tooltip": "Jira"}'
            exit 0
        fi
        
        text=$(echo "$result" | jq -r '.text // "󰌃"')
        tooltip=$(echo "$result" | jq -r '.tooltip // "Jira"')
        class=$(echo "$result" | jq -r '.class // "no-issues"')
        
        # Extract count from text (e.g., "󰌃 5" -> 5)
        count=$(echo "$text" | grep -oE '[0-9]+' || echo "0")
        
        if [[ "$class" == "has-unseen" ]]; then
            alt="unseen"
        elif [[ "$class" == "has-nuevo" ]]; then
            alt="nuevo"
        elif [[ "$class" == "has-issues" ]]; then
            alt="issues"
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
