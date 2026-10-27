#!/bin/bash
# Simple notification key handler
# Opens panel and listens for "e" key

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

get_notification_for_letter() {
    local letter="$1"
    
    # Check OpenCode
    if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
        local info=$(grep "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null)
        if [[ -n "$info" ]]; then
            local notif_id=$(echo "$info" | cut -d: -f2 | cut -d'|' -f1)
            local extra=$(cat "$NOTIF_DIR_OPENCODE/${notif_id}.notif" 2>/dev/null)
            echo "opencode|$notif_id|$letter|$extra"
            return
        fi
    fi
    
    # Check Slack
    if [[ -f "$LETTER_MAP_SLACK" ]]; then
        local info=$(grep "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null)
        if [[ -n "$info" ]]; then
            local notif_id=$(echo "$info" | cut -d: -f2 | cut -d'|' -f1)
            local extra=$(cat "$NOTIF_DIR_SLACK/${notif_id}.notif" 2>/dev/null)
            echo "slack|$notif_id|$letter|$extra"
            return
        fi
    fi
}

trigger_notification() {
    local app="$1"
    local notif_id="$2"
    local letter="$3"
    local extra="$4"
    
    case "$app" in
        opencode)
            local cwd=$(echo "$extra" | cut -d'|' -f2)
            local session=$(echo "$extra" | cut -d'|' -f3)
            
            gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
            rm -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif"
            sed -i "/^${letter}:/d" "$LETTER_MAP_OPENCODE" 2>/dev/null
            
            [[ -n "$cwd" && -n "$session" ]] && /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$cwd" "$session"
            ;;
            
        slack)
            gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
            rm -f "$NOTIF_DIR_SLACK/${notif_id}.notif"
            sed -i "/^${letter}:/d" "$LETTER_MAP_SLACK" 2>/dev/null
            /home/froa/.config/hypr/scripts/invoke-notification.sh
            ;;
    esac
}

# Open notification panel
astal -i hyprpanel -t notificationsmenu 2>/dev/null
sleep 0.1

# Check if there's a notification with letter "e"
notif_info=$(get_notification_for_letter "e")

if [[ -z "$notif_info" ]]; then
    notify-send "No notification for 'e'"
    exit 0
fi

# Show hint
notify-send -t 2000 "Press 'e' to open" "Notification found!" &

# Create a simple key listener using a small script
# Uses wezterm to spawn a tiny window that captures one key
FIFO="/tmp/notif-key-$USER"
rm -f "$FIFO"
mkfifo "$FIFO"

# Try using ydotool or wtype to capture
# For now, use rofi as simple input
KEY=$(echo "" | rofi -dmenu -p "Press 'e':" -lines 0 -kb-cancel "Escape" 2>/dev/null)

if [[ "$KEY" == "e" ]]; then
    # Trigger the notification
    trigger_notification $(echo "$notif_info" | tr '|' ' ')
fi

rm -f "$FIFO"
