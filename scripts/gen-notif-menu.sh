#!/bin/bash
# Generate wlr-which-key notification submenu dynamically
# Each notification letter becomes a direct keybind

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

# Output wlr-which-key submenu config
echo "  # +notifications (dynamically generated)"

# OpenCode notifications
if [[ -d "$NOTIF_DIR_OPENCODE" ]]; then
    for notif_file in "$NOTIF_DIR_OPENCODE"/*.notif; do
        [[ -f "$notif_file" ]] || continue
        notif_id=$(basename "$notif_file" .notif)
        letter=""
        if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
            letter=$(grep ":$notif_id|" "$LETTER_MAP_OPENCODE" 2>/dev/null | cut -d: -f1)
        fi
        [[ -n "$letter" ]] || continue
        
        content=$(cat "$notif_file" | cut -d'|' -f1)
        # Escape special chars for yaml
        content_escaped=$(echo "$content" | sed 's/"/\\"/g')
        
        echo "  - key: \"$letter\""
        echo "    desc: \"🤖 $content_escaped\""
        echo "    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh opencode $notif_id $letter\""
        echo ""
    done
fi

# Slack notifications  
if [[ -d "$NOTIF_DIR_SLACK" ]]; then
    for notif_file in "$NOTIF_DIR_SLACK"/*.notif; do
        [[ -f "$notif_file" ]] || continue
        notif_id=$(basename "$notif_file" .notif)
        letter=""
        if [[ -f "$LETTER_MAP_SLACK" ]]; then
            letter=$(grep ":$notif_id|" "$LETTER_MAP_SLACK" 2>/dev/null | cut -d: -f1)
        fi
        [[ -n "$letter" ]] || continue
        
        content=$(cat "$notif_file")
        content_escaped=$(echo "$content" | sed 's/"/\\"/g')
        
        echo "  - key: \"$letter\""
        echo "    desc: \"💬 $content_escaped\""
        echo "    cmd: ~/.config/hypr/scripts/notif-trigger-direct.sh slack $notif_id $letter\""
        echo ""
    done
fi
