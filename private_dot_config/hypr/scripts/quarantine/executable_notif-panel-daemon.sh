#!/bin/bash
# Start a background daemon that watches for notification panel and captures keys

PIDFILE="/tmp/notif-panel-daemon-$USER.pid"

# Check if already running
if [ -f "$PIDFILE" ]; then
    oldpid=$(cat "$PIDFILE")
    if kill -0 "$oldpid" 2>/dev/null; then
        echo "Daemon already running (pid $oldpid)"
        exit 0
    fi
fi

# Write PID
echo $$ > "$PIDFILE"

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
    local extra="$3"
    
    gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification "$notif_id" 2>/dev/null
    
    if [[ "$app" == "opencode" ]]; then
        rm -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif"
        sed -i "/^${notif_id}:/d" "$LETTER_MAP_OPENCODE" 2>/dev/null
        cwd=$(echo "$extra" | cut -d'|' -f2)
        session=$(echo "$extra" | cut -d'|' -f3)
        [[ -n "$cwd" && -n "$session" ]] && /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$cwd" "$session"
    else
        rm -f "$NOTIF_DIR_SLACK/${notif_id}.notif"
        sed -i "/^${notif_id}:/d" "$LETTER_MAP_SLACK" 2>/dev/null
        /home/froa/.config/hypr/scripts/invoke-notification.sh
    fi
}

check_panel() {
    hyprctl layers 2>/dev/null | grep -q "namespace: notificationsmenu"
}

panel_was_open=false

echo "Daemon started"

while true; do
    if check_panel; then
        if [ "$panel_was_open" = false ]; then
            echo "Panel opened - watching for keys..."
            panel_was_open=true
            
            # Show hint
            notify-send -t 1500 "Press a key" "Notification mode active"
        fi
        
        # Check for keypress using ydotool
        # This is a busy loop but simple
        sleep 0.1
        
    else
        if [ "$panel_was_open" = true ]; then
            echo "Panel closed"
            panel_was_open=false
        fi
        sleep 0.5
    fi
done
