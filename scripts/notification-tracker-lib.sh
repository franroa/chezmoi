#!/bin/bash
# Common notification tracking functions
# Source this file to use: source /home/froa/.config/hypr/scripts/notification-tracker-lib.sh

# Usage:
#   NOTIF_STATE_DIR="/tmp/myapp_notifications_$USER"
#   NOTIF_COUNTER_FILE="/tmp/.myapp_unread_$USER"
#   source /home/froa/.config/hypr/scripts/notification-tracker-lib.sh
#
# Functions provided:
#   notif_get_count       - Returns count of notifications
#   notif_get_sources     - Returns list of sources
#   notif_update_counter  - Updates counter file
#   notif_add            - Adds a notification (id, source, [extra])
#   notif_remove         - Removes a notification (id)
#   notif_clear          - Clears all notifications
#   notif_status         - Outputs status JSON
#   notif_show_sources   - Shows sources via notify-send

notif_get_count() {
    find "$NOTIF_STATE_DIR" -name "*.notif" 2>/dev/null | wc -l
}

notif_get_sources() {
    cat "$NOTIF_STATE_DIR"/*.notif 2>/dev/null | cut -d'|' -f1 | sort | uniq -c | sort -rn | head -3 | awk '{print $2 ": " $1}' | paste -sd ',' -
}

notif_update_counter() {
    local count=$(notif_get_count)
    if [[ "$count" -gt 0 ]]; then
        echo "$count" > "$NOTIF_COUNTER_FILE"
    else
        rm -f "$NOTIF_COUNTER_FILE"
    fi
    # Trigger hyprpanel CSS regeneration if available
    if [[ -x "$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh" ]]; then
        "$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh" &
    fi
}

notif_add() {
    local id="$1"
    local source="$2"
    local extra="${3:-}"
    echo "$source|$extra" > "$NOTIF_STATE_DIR/${id}.notif"
    notif_update_counter
}

notif_remove() {
    local id="$1"
    rm -f "$NOTIF_STATE_DIR/${id}.notif"
    notif_update_counter
}

notif_clear() {
    rm -f "$NOTIF_STATE_DIR"/*.notif
    notif_update_counter
}

notif_status() {
    local count=$(notif_get_count)
    local app_name="${NOTIF_APP_NAME:-Notifications}"
    if [[ "$count" -gt 0 ]]; then
        local sources=$(notif_get_sources)
        echo "{\"text\": \"$count\", \"alt\": \"unread\", \"tooltip\": \"$app_name - $count unread\\n$sources\"}"
    else
        echo "{\"text\": \"\", \"alt\": \"none\", \"tooltip\": \"$app_name\"}"
    fi
}

notif_show_sources() {
    local count=$(notif_get_count)
    local app_name="${NOTIF_APP_NAME:-Notifications}"
    if [[ "$count" -eq 0 ]]; then
        notify-send "$app_name" "No unread notifications"
        return
    fi
    
    local sources=$(cat "$NOTIF_STATE_DIR"/*.notif 2>/dev/null | cut -d'|' -f1 | sort | uniq -c | sort -rn)
    notify-send "$app_name - $count unread" "$sources"
}

# Auto-init if variables are set
if [[ -n "$NOTIF_STATE_DIR" ]]; then
    mkdir -p "$NOTIF_STATE_DIR"
fi
