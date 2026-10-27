#!/bin/bash
# Notification panel key capture using yad
# Shows a small window that captures a keypress

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

get_notification_for_letter() {
    local letter="$1"
    
    # Check OpenCode
    if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
        info=$(grep "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null)
        if [[ -n "$info" ]]; then
            notif_id=$(echo "$info" | cut -d: -f2 | cut -d'|' -f1)
            if [[ -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif" ]]; then
                content=$(cat "$NOTIF_DIR_OPENCODE/${notif_id}.notif")
                echo "opencode|$notif_id|$letter|$content"
                return
            fi
        fi
    fi
    
    # Check Slack
    if [[ -f "$LETTER_MAP_SLACK" ]]; then
        info=$(grep "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null)
        if [[ -n "$info" ]]; then
            notif_id=$(echo "$info" | cut -d: -f2 | cut -d'|' -f1)
            if [[ -f "$NOTIF_DIR_SLACK/${notif_id}.notif" ]]; then
                content=$(cat "$NOTIF_DIR_SLACK/${notif_id}.notif")
                echo "slack|$notif_id|$letter|$content"
                return
            fi
        fi
    fi
}

trigger_notification() {
    local app="$1"
    local notif_id="$2"
    local letter="$3"
    local extra="$4"
    
    # Close notification
    gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
    
    if [[ "$app" == "opencode" ]]; then
        rm -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif"
        sed -i "/^${letter}:/d" "$LETTER_MAP_OPENCODE" 2>/dev/null
        
        cwd=$(echo "$extra" | cut -d'|' -f2)
        session=$(echo "$extra" | cut -d'|' -f3)
        [[ -n "$cwd" && -n "$session" ]] && /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$cwd" "$session"
    else
        rm -f "$NOTIF_DIR_SLACK/${notif_id}.notif"
        sed -i "/^${letter}:/d" "$LETTER_MAP_SLACK" 2>/dev/null
        /home/froa/.config/hypr/scripts/invoke-notification.sh
    fi
}

# Get notifications with letters
notifs=""
for letter in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
    info=$(get_notification_for_letter "$letter")
    [[ -n "$info" ]] && notifs="$notifs$letter "
done

if [[ -z "$notifs" ]]; then
    notify-send "No notification keys"
    exit 0
fi

# Show yad popup to capture key
# Use --key for key capture
key=$(yad --title="Notification Keys" --text="Press a key: $notifs" --width=200 --height=100 --center --no-buttons --key 2>/dev/null)

if [[ -n "$key" ]]; then
    # Find and trigger
    info=$(get_notification_for_letter "$key")
    if [[ -n "$info" ]]; then
        trigger_notification $(echo "$info" | tr '|' ' ')
    fi
fi
