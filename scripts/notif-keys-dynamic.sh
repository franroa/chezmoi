#!/bin/bash
# Generate dynamic notification keys for wlr-which-key

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

# Check for notifications and add keys dynamically
# This script outputs yaml config lines

# Get unique letters
letters=""

# OpenCode
if [[ -d "$NOTIF_DIR_OPENCODE" ]] && [[ -f "$LETTER_MAP_OPENCODE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        letter=$(echo "$line" | cut -d: -f1)
        notif_id=$(echo "$line" | cut -d: -f2 | cut -d'|' -f1)
        [[ -n "$letter" && -n "$notif_id" ]] && letters="$letters$letter "
    done < "$LETTER_MAP_OPENCODE"
fi

# Slack
if [[ -d "$NOTIF_DIR_SLACK" ]] && [[ -f "$LETTER_MAP_SLACK" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        letter=$(echo "$line" | cut -d: -f1)
        notif_id=$(echo "$line" | cut -d: -f2 | cut -d'|' -f1)
        [[ -n "$letter" && -n "$notif_id" ]] && letters="$letters$letter "
    done < "$LETTER_MAP_SLACK"
fi

# Remove duplicates and sort
letters=$(echo "$letters" | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [[ -z "$letters" ]]; then
    echo "  - key: \"h\""
    echo "    desc: \"No notification keys\""
    echo "    cmd: notify-send 'No notifications'"
    exit 0
fi

# Generate a submenu with all letter keys
for letter in $letters; do
    # Get notification info
    info=""
    if [[ -f "$NOTIF_DIR_OPENCODE/.notif" ]]; then
        # Try to find it
        true
    fi
    
    # Check if it's opencode or slack
    if grep -q "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null; then
        echo "  - key: \"$letter\""
        echo "    desc: \"Open OpenCode notification\""
        echo "    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh opencode $letter"
    elif grep -q "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null; then
        echo "  - key: \"$letter\""
        echo "    desc: \"Open Slack notification\""
        echo "    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh slack $letter"
    fi
done
