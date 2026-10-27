#!/bin/bash
# Direct notification trigger from wlr-which-key or dynamic binds

app="$1"
notif_id="$2"
letter="$3"

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

trigger_opencode() {
    local letter="$1"
    local line=$(grep "^${letter}:" "$LETTER_MAP_OPENCODE" 2>/dev/null | head -1)
    if [ -z "$line" ]; then
        return 1
    fi
    
    local notif_id=$(echo "$line" | cut -d':' -f2)
    local extra=$(cat "$NOTIF_DIR_OPENCODE/${notif_id}.notif" 2>/dev/null)
    local cwd=$(echo "$extra" | cut -d'|' -f2)
    local session=$(echo "$extra" | cut -d'|' -f3)
    
    gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
    rm -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif"
    sed -i "/^${letter}:/d" "$LETTER_MAP_OPENCODE" 2>/dev/null
    
    [[ -n "$cwd" && -n "$session" ]] && /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$cwd" "$session"
}

trigger_slack() {
    local letter="$1"
    local line=$(grep "^${letter}:" "$LETTER_MAP_SLACK" 2>/dev/null | head -1)
    if [ -z "$line" ]; then
        return 1
    fi
    
    local notif_id=$(echo "$line" | cut -d':' -f2)
    
    gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
    rm -f "$NOTIF_DIR_SLACK/${notif_id}.notif"
    sed -i "/^${letter}:/d" "$LETTER_MAP_SLACK" 2>/dev/null
    /home/froa/.config/hypr/scripts/invoke-notification.sh
}

# Handle "letter" mode - lookup by letter
if [ "$app" = "letter" ]; then
    # Try opencode first, then slack
    trigger_opencode "$letter" || trigger_slack "$letter"
    exit 0
fi

case "$app" in
    opencode)
        extra=$(cat "$NOTIF_DIR_OPENCODE/${notif_id}.notif" 2>/dev/null)
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
