#!/bin/bash
# OpenCode monitor for HyprPanel
# - Tracks notifications by ID and source
# - Creates letter mappings for notifications

STATE_DIR="/tmp/opencode_notifications_$USER"
LETTER_MAP="/tmp/.opencode_letter_map"
LETTERS_FILE="/tmp/.opencode_letters"
GENERATE_SCRIPT="$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh"

mkdir -p "$STATE_DIR"

LETTERS="abcdefghijklmnopqrstuvwxyz"

get_available_letter() {
    local used=$(cat "$LETTERS_FILE" 2>/dev/null | tr ',' '\n')
    for letter in $(echo "$LETTERS" | grep -o .); do
        if ! echo "$used" | grep -q "^${letter}$"; then
            echo "$letter"
            return 0
        fi
    done
    return 1
}

release_letter() {
    local letter="$1"
    if [[ -n "$letter" ]]; then
        local used=$(cat "$LETTERS_FILE" 2>/dev/null | tr ',' '\n' | grep -v "^${letter}$" | tr '\n' ',' | sed 's/,$//')
        echo "$used" > "$LETTERS_FILE"
        sed -i "/^${letter}:/d" "$LETTER_MAP"
    fi
}

get_count() {
    find "$STATE_DIR" -name "*.notif" 2>/dev/null | wc -l
}

update_blink() {
    local count=$(get_count)
    if [[ "$count" -gt 0 ]]; then
        echo "$count" > "/tmp/.opencode_unread_$USER"
    else
        rm -f "/tmp/.opencode_unread_$USER"
    fi
    [[ -x "$GENERATE_SCRIPT" ]] && "$GENERATE_SCRIPT" &
}

add_notification() {
    local id="$1"
    local cwd="$2"
    local session="$3"
    
    local letter=$(get_available_letter)
    
    if [[ -z "$letter" ]]; then
        echo "No available letters for notification"
        return 1
    fi
    
    echo "OpenCode" > "$STATE_DIR/${id}.notif"
    echo "${letter}:${id}|${cwd}|${session}" >> "$LETTER_MAP"
    
    local used=$(cat "$LETTERS_FILE" 2>/dev/null)
    if [[ -z "$used" ]]; then
        echo "$letter" > "$LETTERS_FILE"
    else
        echo "$used,$letter" > "$LETTERS_FILE"
    fi
    
    update_blink
    echo "Tracking OpenCode notification: id=$id, letter=$letter, cwd=$cwd, session=$session"
}

remove_notification() {
    local id="$1"
    
    if [[ -f "$LETTER_MAP" ]]; then
        local letter=$(grep ":${id}|" "$LETTER_MAP" 2>/dev/null | cut -d: -f1)
        if [[ -n "$letter" ]]; then
            release_letter "$letter"
        fi
    fi
    
    rm -f "$STATE_DIR/${id}.notif"
    update_blink
}

clear_all() {
    rm -f "$STATE_DIR"/*.notif
    rm -f "$LETTER_MAP"
    rm -f "$LETTERS_FILE"
    update_blink
}

monitor() {
    touch "$LETTER_MAP"
    touch "$LETTERS_FILE"
    
    dbus-monitor "interface='org.freedesktop.Notifications'" 2>/dev/null | \
    while IFS= read -r line; do
        # New notification
        if [[ "$line" == *"member=Notify"* ]]; then
            app_name=""
            waiting_for_id=false
        fi
        
        # First string after Notify is app name - if it's OpenCode, track it
        if [[ "$line" == *'string "OpenCode"'* && -z "$app_name" ]]; then
            app_name="opencode"
            waiting_for_id=true
        fi
        
        # Notified signal contains the ID - format: "uint32 <id>"
        if [[ "$waiting_for_id" == true && "$line" == *"uint32 "* && "$line" != *"member="* ]]; then
            notif_id=$(echo "$line" | grep -oP 'uint32 \K[0-9]+')
            if [[ -n "$notif_id" && -n "$app_name" && "$app_name" != "waiting" ]]; then
                add_notification "$notif_id" "/tmp" "default"
            fi
            app_name=""
            waiting_for_id=false
        fi
        
        # Notification closed
        if [[ "$line" == *"member=NotificationClosed"* ]]; then
            read -r id_line
            notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
            [[ -n "$notif_id" ]] && remove_notification "$notif_id"
        fi
    done
}

case "${1:-}" in
    monitor)
        monitor
        ;;
    add)
        add_notification "$2" "$3" "$4"
        ;;
    remove)
        remove_notification "$2"
        ;;
    clear)
        clear_all
        ;;
    count)
        get_count
        ;;
    *)
        echo "Usage: $0 {monitor|add|remove|clear|count}"
        ;;
esac
