#!/bin/bash
# Trigger a notification action from submap keypress
# Args: app notif_id letter extra

app="$1"
notif_id="$2"
letter="$3"
extra="$4"

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

# Exit submap first
hyprctl submap reset

case "$app" in
    opencode)
        cwd=$(echo "$extra" | cut -d'|' -f2)
        session=$(echo "$extra" | cut -d'|' -f3)
        
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
