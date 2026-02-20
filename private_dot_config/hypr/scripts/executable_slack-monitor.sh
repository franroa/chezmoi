#!/bin/bash
# Slack monitor for HyprPanel
# - Tracks notifications by ID and source
# - Decrements on close/action
# - Shows sources on right-click

STATE_DIR="/tmp/slack_notifications_$USER"
GENERATE_SCRIPT="$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh"

mkdir -p "$STATE_DIR"

get_count() {
    find "$STATE_DIR" -name "*.notif" 2>/dev/null | wc -l
}

get_sources() {
    cat "$STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | sort -rn | awk '{print $2 ": " $1}' | paste -sd ',' -
}

update_blink() {
    local count=$(get_count)
    if [[ "$count" -gt 0 ]]; then
        echo "$count" > "/tmp/.slack_unread_$USER"
    else
        rm -f "/tmp/.slack_unread_$USER"
    fi
    [[ -x "$GENERATE_SCRIPT" ]] && "$GENERATE_SCRIPT" &
}

add_notification() {
    local id="$1"
    local source="$2"
    echo "$source" > "$STATE_DIR/${id}.notif"
    update_blink
}

remove_notification() {
    local id="$1"
    rm -f "$STATE_DIR/${id}.notif"
    update_blink
}

clear_all() {
    rm -f "$STATE_DIR"/*.notif
    update_blink
}

status() {
    local count=$(get_count)
    if [[ "$count" -gt 0 ]]; then
        local sources=$(get_sources)
        echo "{\"text\": \"$count\", \"alt\": \"unread\", \"tooltip\": \"Slack - $count unread | $sources\"}"
    else
        echo "{\"text\": \"\", \"alt\": \"none\", \"tooltip\": \"Slack\"}"
    fi
}

show_sources() {
    local count=$(get_count)
    if [[ "$count" -eq 0 ]]; then
        notify-send "Slack" "No unread notifications"
        return
    fi
    
    local sources=$(get_sources | sed 's/\\n/\n/g')
    notify-send "Slack - $count unread" "$sources"
}

monitor() {
    local pending_source=""
    local waiting_for_id=false
    
    dbus-monitor "interface='org.freedesktop.Notifications'" 2>/dev/null | \
    while IFS= read -r line; do
        # New notification - check if from Slack
        if [[ "$line" == *"member=Notify"* ]]; then
            pending_source=""
            waiting_for_id=false
        fi
        
        # First string after Notify is app name
        if [[ "$line" == *'string "Slack"'* && -z "$pending_source" ]]; then
            pending_source="waiting"
        fi
        
        # Get source from "Nuevo mensaje de/en X"
        if [[ "$pending_source" == "waiting" && "$line" == *'string "Nuevo mensaje'* ]]; then
            pending_source=$(echo "$line" | sed 's/.*string "Nuevo mensaje \(en\|de\) \([^"]*\)".*/\2/')
            waiting_for_id=true
        fi
        
        # Notified signal contains the ID - format: "uint32 <id>"
        if [[ "$waiting_for_id" == true && "$line" == *"uint32 "* && "$line" != *"member="* ]]; then
            local notif_id=$(echo "$line" | grep -oP 'uint32 \K[0-9]+')
            if [[ -n "$notif_id" && -n "$pending_source" && "$pending_source" != "waiting" ]]; then
                add_notification "$notif_id" "$pending_source"
            fi
            pending_source=""
            waiting_for_id=false
        fi
        
        # Notification closed or action invoked - next line has ID
        if [[ "$line" == *"member=NotificationClosed"* || "$line" == *"member=ActionInvoked"* ]]; then
            read -r id_line
            local notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
            [[ -n "$notif_id" && -f "$STATE_DIR/${notif_id}.notif" ]] && remove_notification "$notif_id"
        fi
    done
}

monitor_focus() {
    local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
    while IFS= read -r event; do
        [[ "$event" == activewindow\>\>Slack,* ]] && ~/.local/bin/pypr hide "*" 2>/dev/null
    done < <(socat -U - UNIX-CONNECT:"${socket}")
}

start_monitor() {
    # Use flock -n with a command to ensure single instance
    # The flock process stays alive while the command runs
    flock -n /tmp/slack-monitor-$USER.lock -c "
        $0 _run_monitor
    " || exit 0
}

_run_monitor() {
    monitor &
    monitor_focus
}

case "${1:-status}" in
    monitor)      start_monitor ;;
    _run_monitor) _run_monitor ;;
    clear)        clear_all ;;
    count)        get_count ;;
    sources)      show_sources ;;
    status|*)     status ;;
esac
