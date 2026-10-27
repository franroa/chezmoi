#!/bin/bash
# Notification easymotion using wtype to capture keypress
# Opens notification panel then uses wtype to wait for key

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

get_notifications_with_letters() {
    if [[ -d "$NOTIF_DIR_OPENCODE" ]]; then
        for notif_file in "$NOTIF_DIR_OPENCODE"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            notif_id=$(basename "$notif_file" .notif)
            letter=""
            [[ -f "$LETTER_MAP_OPENCODE" ]] && letter=$(grep ":$notif_id|" "$LETTER_MAP_OPENCODE" 2>/dev/null | cut -d: -f1)
            [[ -n "$letter" ]] && echo "opencode|$notif_id|$letter|$(cat "$notif_file")"
        done
    fi
    
    if [[ -d "$NOTIF_DIR_SLACK" ]]; then
        for notif_file in "$NOTIF_DIR_SLACK"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            notif_id=$(basename "$notif_file" .notif)
            letter=""
            [[ -f "$LETTER_MAP_SLACK" ]] && letter=$(grep ":$notif_id|" "$LETTER_MAP_SLACK" 2>/dev/null | cut -d: -f1)
            [[ -n "$letter" ]] && echo "slack|$notif_id|$letter|$(cat "$notif_file")"
        done
    fi
}

trigger_notification() {
    app="$1"
    notif_id="$2"
    letter="$3"
    extra="$4"

    case "$app" in
        opencode)
            cwd=$(echo "$extra" | cut -d'|' -f2)
            session=$(echo "$extra" | cut -d'|' -f3)
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

notifications=$(get_notifications_with_letters)

if [[ -z "$notifications" ]]; then
    astal -i hyprpanel -t notificationsmenu 2>/dev/null
    notify-send "Notifications" "No notifications with letter shortcuts"
    exit 0
fi

# Open notification panel
astal -i hyprpanel -t notificationsmenu 2>/dev/null
sleep 0.1

# Build hint
notif_hint=""
while IFS='|' read -r app notif_id letter extra; do
    [[ -z "$letter" ]] && continue
    content=""
    [[ "$app" == "opencode" ]] && content=$(echo "$extra" | cut -d'|' -f1)
    [[ "$app" == "slack" ]] && content="$extra"
    notif_hint="$notif_hint[$letter] $content "
done <<< "$notifications"

notify-send -t 3000 "Press key (Esc to close):" "$notif_hint" &

# Use rofi in spawn mode to wait for keypress
# Create a simple prompt that waits for single character input
KEY=$(echo "" | rofi -dmenu -p "Press key:" -kb-cancel "Escape" -lines 0 -width 10 2>/dev/null)

# Check if user pressed Escape or cancelled
[[ -z "$KEY" ]] && exit 0

# Find and trigger matching notification
while IFS='|' read -r app notif_id letter extra; do
    if [[ "$letter" == "$KEY" ]]; then
        trigger_notification "$app" "$notif_id" "$letter" "$extra"
        exit 0
    fi
done <<< "$notifications"

notify-send "No notification for: $KEY"
