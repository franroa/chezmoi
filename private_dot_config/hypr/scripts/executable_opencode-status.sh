#!/bin/bash
# OpenCode status for HyprPanel

STATE_DIR="/tmp/opencode_notifications_$USER"

get_count() {
    find "$STATE_DIR" -name "*.notif" 2>/dev/null | wc -l
}

get_sources() {
    cat "$STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | sort -rn | awk '{print $2 ": " $1}' | paste -sd ',' -
}

count=$(get_count)
if [[ "$count" -gt 0 ]]; then
    sources=$(get_sources)
    echo "{\"text\": \"$count\", \"alt\": \"unread\", \"tooltip\": \"OpenCode - $count unread | $sources\"}"
else
    echo "{\"text\": \"\", \"alt\": \"none\", \"tooltip\": \"OpenCode\"}"
fi
