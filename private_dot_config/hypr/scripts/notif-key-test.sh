#!/bin/bash
# Notification panel key capture using yad entry
# Single character entry that triggers on any key

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

get_notification_for_letter() {
    local letter="$1"
    
    if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
        info=$(grep "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null)
        if [[ -n "$info" ]]; then
            notif_id=$(echo "$info" | cut -d: -f2 | cut -d'|' -f1)
            [[ -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif" ]] && cat "$NOTIF_DIR_OPENCODE/${notif_id}.notif" && return
        fi
    fi
    
    if [[ -f "$LETTER_MAP_SLACK" ]]; then
        info=$(grep "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null)
        if [[ -n "$info" ]]; then
            notif_id=$(echo "$info" | cut -d: -f2 | cut -d'|' -f1)
            [[ -f "$NOTIF_DIR_SLACK/${notif_id}.notif" ]] && cat "$NOTIF_DIR_SLACK/${notif_id}.notif" && return
        fi
    fi
}

# List available keys
keys=""
for letter in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
    [[ -n "$(get_notification_for_letter "$letter")" ]] && keys="$keys$letter "
done

[[ -z "$keys" ]] && exit 0

# Use yad entry with timeout - single char
result=$(yad --entry --title="Key" --text="Press key: $keys" --width=150 --height=80 --center --timeout=5 --timeout-indicator=bottom 2>/dev/null)

[[ -n "$result" ]] && echo "$result"
