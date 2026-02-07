#!/bin/bash
STATE_FILE="/tmp/.slack_unread_$USER"
SENDERS_FILE="/tmp/.slack_senders_$USER"
GENERATE_SCRIPT="$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh"

count=0
[[ -f "$STATE_FILE" ]] && count=$(cat "$STATE_FILE")

get_senders() {
    if [[ -f "$SENDERS_FILE" && -s "$SENDERS_FILE" ]]; then
        sort -u "$SENDERS_FILE" | tr '\n' ', ' | sed 's/, $//'
    fi
}

toggle_slack() {
    echo "0" > "$STATE_FILE"
    > "$SENDERS_FILE"
    "$GENERATE_SCRIPT"
    hyprctl dispatch focuswindow "class:com.slack.Slack" 2>/dev/null || \
        flatpak run com.slack.Slack &
}

case "${1:-}" in
    toggle)
        toggle_slack
        exit 0
        ;;
esac

"$GENERATE_SCRIPT"

senders=$(get_senders)

if [[ "$count" -gt 0 ]]; then
    tooltip="Slack - $count unread"
    [[ -n "$senders" ]] && tooltip="$tooltip\\nFrom: $senders"
    echo "{\"text\": \"$count\", \"tooltip\": \"$tooltip\"}"
else
    echo '{"text": "", "tooltip": "Slack"}'
fi
