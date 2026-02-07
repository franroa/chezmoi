#!/bin/bash
# Slack notification tracker for HyprPanel
# Monitors D-Bus notifications and counts Slack messages

STATE_FILE="/tmp/.slack_unread_$USER"
SENDERS_FILE="/tmp/.slack_senders_$USER"

get_count() {
    [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo "0"
}

get_senders() {
    if [[ -f "$SENDERS_FILE" && -s "$SENDERS_FILE" ]]; then
        sort -u "$SENDERS_FILE" | tr '\n' ', ' | sed 's/, $//'
    fi
}

increment() {
    local sender="$1"
    local count=$(get_count)
    echo $((count + 1)) > "$STATE_FILE"
    [[ -n "$sender" ]] && echo "$sender" >> "$SENDERS_FILE"
}

mark_read() {
    echo "0" > "$STATE_FILE"
    > "$SENDERS_FILE"
}

open_slack() {
    mark_read
    hyprctl dispatch focuswindow "class:com.slack.Slack" || \
        flatpak run com.slack.Slack &
}

waybar_output() {
    local count=$(get_count)
    local senders=$(get_senders)
    
    if [[ "$count" -gt 0 ]]; then
        local tooltip="$count unread message(s)"
        [[ -n "$senders" ]] && tooltip="$tooltip\nFrom: $senders"
        echo "{\"text\": \"$count\", \"tooltip\": \"$tooltip\", \"class\": \"has-unread\"}"
    else
        echo "{\"text\": \"\", \"tooltip\": \"Slack - No unread messages\", \"class\": \"no-messages\"}"
    fi
}

monitor() {
    dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null | \
    while read -r line; do
        if [[ "$line" == *"string \"Slack\""* ]] || [[ "$line" == *"string \"com.slack.Slack\""* ]]; then
            read -r title_line
            sender=$(echo "$title_line" | grep -oP 'string "\K[^"]+' | head -1)
            increment "$sender"
        fi
    done
}

case "${1:-waybar}" in
    monitor)
        monitor
        ;;
    increment)
        increment "$2"
        ;;
    mark-read|clear)
        mark_read
        ;;
    open)
        open_slack
        ;;
    count)
        get_count
        ;;
    waybar|*)
        waybar_output
        ;;
esac
