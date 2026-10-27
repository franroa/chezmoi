#!/bin/bash
# Notification easymotion - shows notifications then waits for keypress
# Used by wlr-which-key: press key to activate, then press letter to trigger
# Opens notification panel first, then waits for keypress

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

get_notifications_with_letters() {
    # OpenCode
    if [[ -d "$NOTIF_DIR_OPENCODE" ]]; then
        for notif_file in "$NOTIF_DIR_OPENCODE"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            local notif_id=$(basename "$notif_file" .notif)
            local letter=""
            if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
                letter=$(grep ":$notif_id|" "$LETTER_MAP_OPENCODE" 2>/dev/null | cut -d: -f1)
            fi
            [[ -n "$letter" ]] && echo "opencode|$notif_id|$letter|$(cat "$notif_file")"
        done
    fi
    
    # Slack
    if [[ -d "$NOTIF_DIR_SLACK" ]]; then
        for notif_file in "$NOTIF_DIR_SLACK"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            local notif_id=$(basename "$notif_file" .notif)
            local letter=""
            if [[ -f "$LETTER_MAP_SLACK" ]]; then
                letter=$(grep ":$notif_id|" "$LETTER_MAP_SLACK" 2>/dev/null | cut -d: -f1)
            fi
            [[ -n "$letter" ]] && echo "slack|$notif_id|$letter|$(cat "$notif_file")"
        done
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
            
            # Close notification
            gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
            
            # Remove from tracker
            rm -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif"
            sed -i "/^${letter}:/d" "$LETTER_MAP_OPENCODE" 2>/dev/null
            
            # Open session
            [[ -n "$cwd" && -n "$session" ]] && /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$cwd" "$session"
            ;;
            
        slack)
            # Close notification
            gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
            
            # Remove from tracker
            rm -f "$NOTIF_DIR_SLACK/${notif_id}.notif"
            sed -i "/^${letter}:/d" "$LETTER_MAP_SLACK" 2>/dev/null
            
            # Go to Slack
            /home/froa/.config/hypr/scripts/invoke-notification.sh
            ;;
    esac
}

# Get notifications
notifications=$(get_notifications_with_letters)

if [[ -z "$notifications" ]]; then
    notify-send "Notifications" "No notifications with letter shortcuts"
    exit 0
fi

# Build notification list for display
notif_list=""
while IFS='|' read -r app notif_id letter extra; do
    [[ -z "$letter" ]] && continue
    
    local content=""
    case "$app" in
        opencode)
            content=$(echo "$extra" | cut -d'|' -f1)
            ;;
        slack)
            content="$extra"
            ;;
    esac
    notif_list="$notif_list[$letter] $content\n"
done <<< "$notifications"

# Open notification panel first
swaync-client -t -sw 2>/dev/null
sleep 0.15

# Show notification hint
echo -e "$notif_list" | head -5 | sed 's/\\n/\n/g' | while read line; do
    [[ -n "$line" ]] && notify-send -t 2000 "Press key for notification" "$line" 2>/dev/null
done &

# Use a fifo to wait for keypress via wtype
FIFO=$(mktemp -u)
mkfifo "$FIFO"

# Start wtype in background reading from fifo - but we want it to wait
# Instead use wezterm to wait for key
wezterm cli spawn --plain-text -- bash -c "read -n1 key; echo \$key > $FIFO" 2>/dev/null &
WPID=$!

# Wait for key with timeout
timeout 3 cat "$FIFO" 2>/dev/null
KEY=$(cat "$FIFO" 2>/dev/null)

kill $WPID 2>/dev/null
rm -f "$FIFO"

# Find and trigger the notification with that letter
if [[ -n "$KEY" ]]; then
    while IFS='|' read -r app notif_id letter extra; do
        if [[ "$letter" == "$KEY" ]]; then
            trigger_notification "$app" "$notif_id" "$letter" "$extra"
            exit 0
        fi
    done <<< "$notifications"
    
    # No match found
    notify-send "Notifications" "No notification for key: $KEY"
fi
