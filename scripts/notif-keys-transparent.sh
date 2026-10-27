#!/bin/bash
# Transparent key capture using yad

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
            [[ -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif" ]] && echo "opencode|$notif_id|$(cat "$NOTIF_DIR_OPENCODE/${notif_id}.notif")" && return
        fi
    fi
    
    if [[ -f "$LETTER_MAP_SLACK" ]]; then
        info=$(grep "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null)
        if [[ -n "$info" ]]; then
            notif_id=$(echo "$info" | cut -d: -f2 | cut -d'|' -f1)
            [[ -f "$NOTIF_DIR_SLACK/${notif_id}.notif" ]] && echo "slack|$notif_id|$(cat "$NOTIF_DIR_SLACK/${notif_id}.notif")" && return
        fi
    fi
}

trigger_notification() {
    local app="$1"
    local notif_id="$2"
    local letter="$3"
    local extra="$4"
    
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

# Open notification panel
astal -i hyprpanel -t notificationsmenu 2>/dev/null
sleep 0.1

# Get available keys
keys=""
for letter in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
    [[ -n "$(get_notification_for_letter "$letter")" ]] && keys="$keys$letter "
done

[[ -z "$keys" ]] && exit 0

# Show hint
notify-send -t 1500 "Press key:" "$keys"

# Create minimal yad window - almost invisible, focused
# This will capture keyboard input
yad --form \
    --title=" " \
    --text=" " \
    --field=" ":LBL \
    --width=1 --height=1 \
    --center \
    --no-buttons \
    --skip-taskbar \
    --sticky \
    --undecorated \
    --alpha=1 \
    --timeout=5 \
    --timeout-indicator=bottom \
    --key 2>/dev/null

key=$(cat /dev/stdin 2>/dev/null)

if [[ -n "$key" ]]; then
    info=$(get_notification_for_letter "$key")
    [[ -n "$info" ]] && trigger_notification $(echo "$info" | tr '|' ' ')
fi
