#!/bin/bash
# Unified notification monitor for HyprPanel
# Tracks Slack and OpenCode notifications

SLACK_STATE_DIR="/tmp/slack_notifications_$USER"
OPENCODE_STATE_DIR="/tmp/opencode_notifications_$USER"
GENERATE_SCRIPT="$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh"

mkdir -p "$SLACK_STATE_DIR" "$OPENCODE_STATE_DIR"

# --- Shared functions ---
get_slack_count() { find "$SLACK_STATE_DIR" -name "*.notif" 2>/dev/null | wc -l; }
get_opencode_count() { find "$OPENCODE_STATE_DIR" -name "*.notif" 2>/dev/null | wc -l; }

update_blink() {
    local slack_count=$(get_slack_count)
    local opencode_count=$(get_opencode_count)
    [[ "$slack_count" -gt 0 ]] && echo "$slack_count" > "/tmp/.slack_unread_$USER" || rm -f "/tmp/.slack_unread_$USER"
    [[ "$opencode_count" -gt 0 ]] && echo "$opencode_count" > "/tmp/.opencode_unread_$USER" || rm -f "/tmp/.opencode_unread_$USER"
    [[ -x "$GENERATE_SCRIPT" ]] && "$GENERATE_SCRIPT" &
}

# --- Slack functions ---
add_slack_notification() {
    local id="$1" source="$2"
    echo "$source" > "$SLACK_STATE_DIR/${id}.notif"
    update_blink
}
remove_slack_notification() {
    local id="$1"
    rm -f "$SLACK_STATE_DIR/${id}.notif"
    update_blink
}
slack_status() {
    local count=$(get_slack_count)
    if [[ "$count" -gt 0 ]]; then
        local sources=$(cat "$SLACK_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}' | paste -sd ',' -)
        echo "{\"text\": \"$count\", \"alt\": \"unread\", \"tooltip\": \"Slack - $count unread | $sources\"}"
    else
        echo "{\"text\": \"\", \"alt\": \"none\", \"tooltip\": \"Slack\"}"
    fi
}
slack_sources() {
    local count=$(get_slack_count)
    if [[ "$count" -eq 0 ]]; then
        notify-send "Slack" "No unread notifications"
        return
    fi
    local sources=$(cat "$SLACK_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}')
    notify-send "Slack - $count unread" "$sources"
}

# --- OpenCode functions ---
add_opencode_notification() {
    local id="$1" cwd="$2" session="$3"
    echo "${cwd}|${session}" > "$OPENCODE_STATE_DIR/${id}.notif"
    update_blink
}
remove_opencode_notification() {
    local id="$1"
    rm -f "$OPENCODE_STATE_DIR/${id}.notif"
    update_blink
}
opencode_status() {
    local count=$(get_opencode_count)
    if [[ "$count" -gt 0 ]]; then
        local sources=$(cat "$OPENCODE_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}' | paste -sd ',' -)
        echo "{\"text\": \"$count\", \"alt\": \"unread\", \"tooltip\": \"OpenCode - $count unread | $sources\"}"
    else
        echo "{\"text\": \"\", \"alt\": \"none\", \"tooltip\": \"OpenCode\"}"
    fi
}
opencode_sources() {
    local count=$(get_opencode_count)
    if [[ "$count" -eq 0 ]]; then
        notify-send "OpenCode" "No unread notifications"
        return
    fi
    local sources=$(cat "$OPENCODE_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}')
    notify-send "OpenCode - $count unread" "$sources"
}

# --- Unified monitor ---
monitor() {
    # pending_app is set when we see member=Notify + a known app name.
    # The real notification ID comes back in the Notified signal, not in the Notify args
    # (uint32 in Notify args is replaces_id, not the assigned ID).
    pending_app=""

    dbus-monitor "interface='org.freedesktop.Notifications'" 2>/dev/null | \
    while IFS= read -r line; do

        # New Notify call — reset pending app
        if [[ "$line" == *"member=Notify"* ]]; then
            pending_app=""
            continue
        fi

        # Detect app name in the Notify call arguments
        if [[ "$line" == *'string "Slack"'* ]]; then
            pending_app="slack"
            continue
        fi
        if [[ "$line" == *'string "OpenCode"'* ]]; then
            pending_app="opencode"
            continue
        fi

        # Notified signal carries the real assigned notification ID
        if [[ "$line" == *"member=Notified"* ]]; then
            # Next non-blank line is: "   uint32 <id>"
            while IFS= read -r id_line; do
                [[ -z "${id_line// }" ]] && continue
                notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
                [[ -z "$notif_id" ]] && break
                if [[ "$pending_app" == "slack" ]]; then
                    add_slack_notification "$notif_id" "slack"
                elif [[ "$pending_app" == "opencode" ]]; then
                    add_opencode_notification "$notif_id" "/tmp" "default"
                fi
                pending_app=""
                break
            done
            continue
        fi

        # Notification closed — remove from whichever state dir owns it
        if [[ "$line" == *"member=NotificationClosed"* ]]; then
            while IFS= read -r id_line; do
                [[ -z "${id_line// }" ]] && continue
                notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
                [[ -z "$notif_id" ]] && break
                [[ -f "$SLACK_STATE_DIR/${notif_id}.notif" ]]    && remove_slack_notification "$notif_id"
                [[ -f "$OPENCODE_STATE_DIR/${notif_id}.notif" ]] && remove_opencode_notification "$notif_id"
                break
            done
            continue
        fi

    done
}

# --- Commands ---
case "${1:-}" in
    monitor)            monitor ;;
    slack-status)       slack_status ;;
    slack-sources)     slack_sources ;;
    slack-clear)
        rm -f "$SLACK_STATE_DIR"/*.notif; update_blink ;;
    opencode-status)    opencode_status ;;
    opencode-sources)  opencode_sources ;;
    opencode-clear)
        rm -f "$OPENCODE_STATE_DIR"/*.notif; update_blink ;;
    *) 
        echo "Usage: $0 {monitor|slack-status|slack-sources|slack-clear|opencode-status|opencode-sources|opencode-clear}"
        ;;
esac
