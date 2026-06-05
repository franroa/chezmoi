#!/bin/bash
# Watch for ActionInvoked on Slack notifications, invoke the action to navigate
# Slack to the source message, then focus workspace 4.
# Needed since Hyprland 0.55 tightened XDG activation token requirements,
# breaking focus_on_activate=false + notification action clicks.

SLACK_STATE_DIR="/tmp/slack_notifications_${USER}"
LOCK_FILE="/tmp/slack-action-focus-${USER}.lock"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

is_slack_notification() {
    local notif_id="$1"
    # Check .notif file first (fast path when notif-monitor.sh is running)
    [[ -f "${SLACK_STATE_DIR}/${notif_id}.notif" ]] && return 0
    # Fallback: query HyprPanel directly
    local json
    json=$(busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
        org.freedesktop.Notifications GetNotificationJson u "$notif_id" 2>/dev/null)
    echo "$json" | grep -qi 'app_name.*Slack'
}

focus_and_navigate() {
    local notif_id="$1"
    local action_id="$2"  # captured before sleep to avoid file-deletion race

    # If action_id is a URL, open it so Slack navigates to the specific message.
    if [[ "$action_id" =~ ^(slack://|https://) ]]; then
        xdg-open "$action_id" 2>/dev/null
    else
        # action_id is opaque (e.g. "default") — re-emit ActionInvoked so Slack
        # can look up the message by its own notification ID.
        busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
            org.freedesktop.Notifications EmitActionInvoked us \
            "$notif_id" "${action_id:-default}" 2>/dev/null
    fi

    # Move to workspace 4 (where Slack lives) and bring it to focus.
    hyprctl dispatch workspace 4 2>/dev/null
    sleep 0.15
    hyprctl dispatch focuswindow "class:slack" 2>/dev/null
}

dbus-monitor "interface='org.freedesktop.Notifications',member='ActionInvoked'" 2>/dev/null | \
while IFS= read -r line; do
    if [[ "$line" == *"member=ActionInvoked"* ]]; then
        notif_id=""
        while IFS= read -r id_line; do
            [[ -z "${id_line// }" ]] && continue
            notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
            break
        done
        if [[ -n "$notif_id" ]] && is_slack_notification "$notif_id"; then
            # Capture action_id NOW — NotificationClosed will delete the .notif
            # file during the sleep below, causing a race if we read it later.
            action_id=$(cat "${SLACK_STATE_DIR}/${notif_id}.notif" 2>/dev/null)
            # Small delay so Slack receives the ActionInvoked signal first.
            sleep 0.3
            focus_and_navigate "$notif_id" "$action_id"
        fi
    fi
done
