#!/bin/bash
# Generate notification keys as direct keybinds for wlr-which-key

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

# Get unique letters from notifications
letters=""

if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        letter=$(echo "$line" | cut -d: -f1)
        [[ -n "$letter" ]] && letters="$letters $letter"
    done < "$LETTER_MAP_OPENCODE"
fi

if [[ -f "$LETTER_MAP_SLACK" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        letter=$(echo "$line" | cut -d: -f1)
        [[ -n "$letter" ]] && letters="$letters $letter"
    done < "$LETTER_MAP_SLACK"
fi

# Remove duplicates
letters=$(echo "$letters" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

if [[ -z "$letters" ]]; then
    echo "No notifications"
    exit 0
fi

#lr-which-key config
echo "# Build w Generated notification keys"
echo "menu:"

for letter in $letters; do
    # Determine if opencode or slack
    if grep -q "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null; then
        echo "  - key: \"$letter\""
        echo "    desc: \"Open OpenCode notification\""
        echo "    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh opencode $letter\""
    else
        echo "  - key: \"$letter\""
        echo "    desc: \"Open Slack notification\""
        echo "    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh slack $letter\""
    fi
done
