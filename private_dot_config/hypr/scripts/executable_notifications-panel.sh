#!/bin/bash
# Notification panel waybar module
# Shows notification count and allows key triggers

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

get_letter_for_notif() {
    local notif_id="$1"
    local app="$2"
    
    case "$app" in
        opencode)
            if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
                grep ":$notif_id|" "$LETTER_MAP_OPENCODE" 2>/dev/null | cut -d: -f1
            fi
            ;;
        slack)
            if [[ -f "$LETTER_MAP_SLACK" ]]; then
                grep ":$notif_id|" "$LETTER_MAP_SLACK" 2>/dev/null | cut -d: -f1
            fi
            ;;
    esac
}

get_notifications() {
    local count=0
    local tooltip=""
    local entries=""
    
    # OpenCode notifications
    if [[ -d "$NOTIF_DIR_OPENCODE" ]]; then
        for notif_file in "$NOTIF_DIR_OPENCODE"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            ((count++))
            local notif_id=$(basename "$notif_file" .notif)
            local letter=$(get_letter_for_notif "$notif_id" "opencode")
            local content=$(cat "$notif_file" | cut -d'|' -f1)
            entries="$entries
[$letter] OpenCode: $content"
        done
    fi
    
    # Slack notifications
    if [[ -d "$NOTIF_DIR_SLACK" ]]; then
        for notif_file in "$NOTIF_DIR_SLACK"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            ((count++))
            local notif_id=$(basename "$notif_file" .notif)
            local letter=$(get_letter_for_notif "$notif_id" "slack")
            local content=$(cat "$notif_file")
            entries="$entries
[$letter] Slack: $content"
        done
    fi
    
    if [[ $count -eq 0 ]]; then
        echo '{"text": "", "tooltip": "No notifications"}'
    else
        tooltip="Notifications ($count)
$entries"
        echo "{\"text\": \"$count\", \"tooltip\": \"$tooltip\"}"
    fi
}

trigger_notification() {
    local letter="$1"
    
    # Check OpenCode
    if [[ -d "$NOTIF_DIR_OPENCODE" ]] && [[ -f "$LETTER_MAP_OPENCODE" ]]; then
        local notif_info=$(grep "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null)
        if [[ -n "$notif_info" ]]; then
            local notif_id=$(echo "$notif_info" | cut -d: -f2 | cut -d'|' -f1)
            local content=$(cat "$NOTIF_DIR_OPENCODE/${notif_id}.notif" 2>/dev/null)
            local cwd=$(echo "$content" | cut -d'|' -f2)
            local session=$(echo "$content" | cut -d'|' -f3)
            
            # Close notification
            gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
            
            # Remove from tracker
            rm -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif"
            sed -i "/^${letter}:/d" "$LETTER_MAP_OPENCODE"
            
            # Open session
            [[ -n "$cwd" && -n "$session" ]] && /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$cwd" "$session"
            exit 0
        fi
    fi
    
    # Check Slack
    if [[ -d "$NOTIF_DIR_SLACK" ]] && [[ -f "$LETTER_MAP_SLACK" ]]; then
        local notif_info=$(grep "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null)
        if [[ -n "$notif_info" ]]; then
            local notif_id=$(echo "$notif_info" | cut -d: -f2 | cut -d'|' -f1)
            
            # Close notification
            gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
            
            # Remove from tracker
            rm -f "$NOTIF_DIR_SLACK/${notif_id}.notif"
            sed -i "/^${letter}:/d" "$LETTER_MAP_SLACK"
            
            # Go to Slack
            /home/froa/.config/hypr/scripts/invoke-notification.sh
            exit 0
        fi
    fi
}

# Handle argument
case "${1:-status}" in
    status)
        get_notifications
        ;;
    trigger)
        trigger_notification "$2"
        ;;
    panel)
        # Show rofi panel with all notifications
        ~/.config/hypr/scripts/notification-panel.sh show
        ;;
esac
