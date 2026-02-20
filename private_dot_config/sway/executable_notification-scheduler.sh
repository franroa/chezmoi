#!/bin/bash
# Notification Scheduler - Manage scheduled notifications
# Uses systemd user timers for reliable scheduling

set -euo pipefail

SCHEDULE_DIR="$HOME/.config/scheduled-notifications"
SYSTEMD_DIR="$HOME/.config/systemd/user"

mkdir -p "$SCHEDULE_DIR" "$SYSTEMD_DIR"

notify() {
    notify-send -t 3000 "Notification Scheduler" "$1"
}

# ═══════════════════════════════════════════════════════════════════
# NOTIFICATION DEFINITIONS
# ═══════════════════════════════════════════════════════════════════

list_notifications() {
    cat "$SCHEDULE_DIR"/*.json 2>/dev/null | jq -s '.' || echo "[]"
}

add_notification() {
    local name="$1"
    local time="$2"
    local message="$3"
    local icon="${4:-dialog-information}"
    # All scheduled notifications are critical (bypass DND/Focus Mode)
    local critical="true"
    
    local id
    id=$(echo "$name" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')
    
    # All scheduled notifications bypass DND
    local urgency="critical"
    
    # Save notification config
    cat > "$SCHEDULE_DIR/$id.json" << EOF
{
    "id": "$id",
    "name": "$name",
    "time": "$time",
    "message": "$message",
    "icon": "$icon",
    "critical": $critical,
    "enabled": true
}
EOF
    
    # Create systemd service
    cat > "$SYSTEMD_DIR/notify-$id.service" << EOF
[Unit]
Description=Scheduled notification: $name

[Service]
Type=oneshot
ExecStart=/usr/bin/notify-send -u $urgency -i $icon "$name" "$message"
EOF
    
    # Create systemd timer
    cat > "$SYSTEMD_DIR/notify-$id.timer" << EOF
[Unit]
Description=Timer for: $name

[Timer]
OnCalendar=*-*-* $time:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Enable timer
    systemctl --user daemon-reload
    systemctl --user enable --now "notify-$id.timer" 2>/dev/null || true
    
    notify "Added: $name at $time"
}

remove_notification() {
    local id="$1"
    
    # Stop and disable timer
    systemctl --user disable --now "notify-$id.timer" 2>/dev/null || true
    
    # Remove files
    rm -f "$SCHEDULE_DIR/$id.json"
    rm -f "$SYSTEMD_DIR/notify-$id.service"
    rm -f "$SYSTEMD_DIR/notify-$id.timer"
    
    systemctl --user daemon-reload
    notify "Removed notification: $id"
}

toggle_notification() {
    local id="$1"
    
    if systemctl --user is-enabled "notify-$id.timer" &>/dev/null; then
        systemctl --user disable --now "notify-$id.timer"
        jq '.enabled = false' "$SCHEDULE_DIR/$id.json" > "$SCHEDULE_DIR/$id.json.tmp"
        mv "$SCHEDULE_DIR/$id.json.tmp" "$SCHEDULE_DIR/$id.json"
        notify "Disabled: $id"
    else
        systemctl --user enable --now "notify-$id.timer"
        jq '.enabled = true' "$SCHEDULE_DIR/$id.json" > "$SCHEDULE_DIR/$id.json.tmp"
        mv "$SCHEDULE_DIR/$id.json.tmp" "$SCHEDULE_DIR/$id.json"
        notify "Enabled: $id"
    fi
}

toggle_critical() {
    local id="$1"
    local json_file="$SCHEDULE_DIR/$id.json"
    
    local current_critical
    current_critical=$(jq -r '.critical // false' "$json_file")
    
    local new_critical="true"
    [[ "$current_critical" == "true" ]] && new_critical="false"
    
    # Update JSON
    jq ".critical = $new_critical" "$json_file" > "$json_file.tmp"
    mv "$json_file.tmp" "$json_file"
    
    # Regenerate service with new urgency
    local name message icon urgency
    name=$(jq -r '.name' "$json_file")
    message=$(jq -r '.message' "$json_file")
    icon=$(jq -r '.icon' "$json_file")
    urgency="normal"
    [[ "$new_critical" == "true" ]] && urgency="critical"
    
    cat > "$SYSTEMD_DIR/notify-$id.service" << EOF
[Unit]
Description=Scheduled notification: $name

[Service]
Type=oneshot
ExecStart=/usr/bin/notify-send -u $urgency -i $icon "$name" "$message"
EOF
    
    systemctl --user daemon-reload
    
    if [[ "$new_critical" == "true" ]]; then
        notify "$name: Now CRITICAL (bypasses DND)"
    else
        notify "$name: Now normal priority"
    fi
}

edit_notification() {
    local id="$1"
    local json_file="$SCHEDULE_DIR/$id.json"
    
    if [[ ! -f "$json_file" ]]; then
        notify "Notification not found: $id"
        return 1
    fi
    
    local current_name current_time current_message current_critical
    current_name=$(jq -r '.name' "$json_file")
    current_time=$(jq -r '.time' "$json_file")
    current_message=$(jq -r '.message' "$json_file")
    current_critical=$(jq -r '.critical // false' "$json_file")
    
    # Ask what to edit
    local field
    field=$(echo -e "󰏫 Name: $current_name\n󰥔 Time: $current_time\n󰍩 Message: $current_message" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Edit field")
    [[ -z "$field" ]] && return
    
    case "$field" in
        *"Name"*)
            local new_name
            new_name=$(echo "" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "New name (current: $current_name)")
            [[ -z "$new_name" ]] && return
            jq --arg v "$new_name" '.name = $v' "$json_file" > "$json_file.tmp"
            mv "$json_file.tmp" "$json_file"
            
            # Update service description
            sed -i "s/Description=.*/Description=Scheduled notification: $new_name/" "$SYSTEMD_DIR/notify-$id.service"
            ;;
        *"Time"*)
            local new_time
            new_time=$(echo "" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "New time HH:MM (current: $current_time)")
            [[ -z "$new_time" ]] && return
            if ! [[ "$new_time" =~ ^[0-2][0-9]:[0-5][0-9]$ ]]; then
                notify "Invalid time format"
                return
            fi
            jq --arg v "$new_time" '.time = $v' "$json_file" > "$json_file.tmp"
            mv "$json_file.tmp" "$json_file"
            
            # Update timer
            sed -i "s/OnCalendar=.*/OnCalendar=*-*-* $new_time:00/" "$SYSTEMD_DIR/notify-$id.timer"
            ;;
        *"Message"*)
            local new_message
            new_message=$(echo "" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "New message (current: $current_message)")
            [[ -z "$new_message" ]] && return
            jq --arg v "$new_message" '.message = $v' "$json_file" > "$json_file.tmp"
            mv "$json_file.tmp" "$json_file"
            
            # Regenerate service
            local name icon urgency
            name=$(jq -r '.name' "$json_file")
            icon=$(jq -r '.icon' "$json_file")
            urgency="normal"
            [[ "$current_critical" == "true" ]] && urgency="critical"
            
            cat > "$SYSTEMD_DIR/notify-$id.service" << EOF
[Unit]
Description=Scheduled notification: $name

[Service]
Type=oneshot
ExecStart=/usr/bin/notify-send -u $urgency -i $icon "$name" "$new_message"
EOF
            ;;
    esac
    
    systemctl --user daemon-reload
    systemctl --user restart "notify-$id.timer" 2>/dev/null || true
    notify "Updated: $current_name"
}

# ═══════════════════════════════════════════════════════════════════
# INITIAL SETUP - Default notifications
# ═══════════════════════════════════════════════════════════════════

setup_defaults() {
    # Remove existing and recreate
    rm -f "$SCHEDULE_DIR"/*.json
    rm -f "$SYSTEMD_DIR"/notify-*.service
    rm -f "$SYSTEMD_DIR"/notify-*.timer
    
    add_notification "Angelus" "12:00" "🙏 Time for the Angelus prayer" "dialog-information" "false"
    add_notification "Juan José" "14:15" "📞 Juan José" "dialog-information" "true"
    add_notification "Divina Misericordia" "15:00" "🙏 Hour of Divine Mercy" "dialog-information" "false"
    notify "Default notifications configured"
}

# ═══════════════════════════════════════════════════════════════════
# WOFI MENU
# ═══════════════════════════════════════════════════════════════════

show_menu() {
    # Build menu from saved notifications
    local menu="󰐊 Add new notification\n───────────────────"
    
    # Build associative array for ID lookup
    declare -A id_map
    
    shopt -s nullglob
    for f in "$SCHEDULE_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        local name time enabled critical id
        id=$(jq -r '.id' "$f")
        name=$(jq -r '.name' "$f")
        time=$(jq -r '.time' "$f")
        enabled=$(jq -r '.enabled' "$f")
        critical=$(jq -r '.critical // false' "$f")
        
        local status_icon="󰔡"
        [[ "$enabled" == "true" ]] && status_icon="󰔟"
        
        local critical_mark=""
        [[ "$critical" == "true" ]] && critical_mark=" 🔴"
        
        local entry="$status_icon $name ($time)$critical_mark"
        menu+="\n$entry"
        id_map["$entry"]="$id|$name"
    done
    shopt -u nullglob
    
    menu+="\n───────────────────"
    menu+="\n󰑓 Reload timers"
    menu+="\n󰒓 Reset to defaults"
    
    local selected
    selected=$(echo -e "$menu" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Scheduled Notifications")
    [[ -z "$selected" ]] && exit 0
    
    case "$selected" in
        *"Add new"*)
            add_new_dialog
            ;;
        *"Reload"*)
            systemctl --user daemon-reload
            notify "Timers reloaded"
            ;;
        *"Reset to defaults"*)
            setup_defaults
            ;;
        "───"*)
            exit 0
            ;;
        *)
            # Look up ID from map
            local lookup="${id_map[$selected]:-}"
            if [[ -n "$lookup" ]]; then
                local id name
                id="${lookup%%|*}"
                name="${lookup#*|}"
                show_notification_actions "$id" "$name"
            else
                notify "Could not find notification"
            fi
            ;;
    esac
}

add_new_dialog() {
    local name
    name=$(echo "" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Notification name")
    [[ -z "$name" ]] && return
    
    local time
    time=$(echo "" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Time (HH:MM, 24h format)")
    [[ -z "$time" ]] && return
    
    # Validate time format
    if ! [[ "$time" =~ ^[0-2][0-9]:[0-5][0-9]$ ]]; then
        notify "Invalid time format. Use HH:MM (e.g., 14:30)"
        return
    fi
    
    local message
    message=$(echo "" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Message (optional)")
    [[ -z "$message" ]] && message="$name"
    
    local critical="false"
    local critical_choice
    critical_choice=$(echo -e "No\nYes (bypass DND)" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Critical notification?")
    [[ "$critical_choice" == *"Yes"* ]] && critical="true"
    
    add_notification "$name" "$time" "$message" "dialog-information" "$critical"
}

show_notification_actions() {
    local id="$1"
    local name="$2"
    local json_file="$SCHEDULE_DIR/$id.json"
    
    local critical
    critical=$(jq -r '.critical // false' "$json_file")
    local critical_label="󰀦 Make critical (bypass DND)"
    [[ "$critical" == "true" ]] && critical_label="󰀧 Make normal (respect DND)"
    
    local actions="󰏫 Edit notification\n󰔟 Toggle enable/disable\n$critical_label\n󰆴 Delete notification\n󰄬 Test notification now"
    
    local action
    action=$(echo -e "$actions" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "$name")
    
    case "$action" in
        *"Edit"*)
            edit_notification "$id"
            ;;
        *"Toggle"*)
            toggle_notification "$id"
            ;;
        *"critical"*|*"normal"*)
            toggle_critical "$id"
            ;;
        *"Delete"*)
            remove_notification "$id"
            ;;
        *"Test"*)
            local msg urgency
            msg=$(jq -r '.message' "$json_file")
            urgency="normal"
            [[ "$critical" == "true" ]] && urgency="critical"
            notify-send -u "$urgency" "$name" "$msg"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

case "${1:-}" in
    setup) setup_defaults ;;
    add) add_notification "$2" "$3" "$4" "${5:-dialog-information}" "${6:-false}" ;;
    remove) remove_notification "$2" ;;
    toggle) toggle_notification "$2" ;;
    critical) toggle_critical "$2" ;;
    edit) edit_notification "$2" ;;
    list) list_notifications ;;
    *) show_menu ;;
esac
