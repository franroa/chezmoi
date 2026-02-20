#!/bin/bash
# Open the latest Slack notification using hyprpanel's EmitActionInvoked
# This triggers the "default" action on the notification, opening Slack to the conversation
# Then closes the notification to remove it from the list and update blink state

NOTIF_DIR="/tmp/slack_notifications_${USER}"

# Get the latest notification ID from our tracking directory
get_latest_slack_notif_id() {
    if [[ -d "$NOTIF_DIR" ]]; then
        # Get the most recent .notif file and extract the ID from filename
        local latest=$(ls -t "$NOTIF_DIR"/*.notif 2>/dev/null | head -1)
        if [[ -n "$latest" ]]; then
            basename "$latest" .notif
        fi
    fi
}

# Fallback: query hyprpanel for Slack notifications directly
get_slack_notif_from_hyprpanel() {
    # Get all notification IDs
    local ids=$(busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
        org.freedesktop.Notifications NotificationIds 2>/dev/null | grep -oP '\d+' | tail -n +2)
    
    # Find the latest Slack notification
    for id in $ids; do
        local json=$(busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
            org.freedesktop.Notifications GetNotificationJson u "$id" 2>/dev/null | sed 's/^s "//' | sed 's/"$//')
        if echo "$json" | grep -q '"app_name":"Slack"'; then
            echo "$id"
            return
        fi
    done
}

# Invoke the notification action
invoke_notification() {
    local notif_id="$1"
    if [[ -n "$notif_id" ]]; then
        busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
            org.freedesktop.Notifications EmitActionInvoked us "$notif_id" "default" 2>/dev/null
        return $?
    fi
    return 1
}

# Close the notification (removes from notification list)
close_notification() {
    local notif_id="$1"
    if [[ -n "$notif_id" ]]; then
        busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
            org.freedesktop.Notifications CloseNotification u "$notif_id" 2>/dev/null
    fi
}

# Main logic
main() {
    # Hide all pyprland scratchpads first
    ~/.local/bin/pypr hide "*" 2>/dev/null
    
    # Try our tracked notification first
    local notif_id=$(get_latest_slack_notif_id)
    
    # If we have a tracked ID, verify it's still valid in hyprpanel
    if [[ -n "$notif_id" ]]; then
        # Check if notification still exists
        local exists=$(busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
            org.freedesktop.Notifications GetNotificationJson u "$notif_id" 2>/dev/null)
        if [[ -z "$exists" ]]; then
            # Notification no longer exists in hyprpanel, clean up our tracking
            rm -f "$NOTIF_DIR/${notif_id}.notif" 2>/dev/null
            notif_id=""
        fi
    fi
    
    # Fallback to querying hyprpanel directly
    if [[ -z "$notif_id" ]]; then
        notif_id=$(get_slack_notif_from_hyprpanel)
    fi
    
    # If we have a notification, invoke it and close it
    if [[ -n "$notif_id" ]]; then
        if invoke_notification "$notif_id"; then
            # Close the notification - this triggers NotificationClosed signal
            # which slack-monitor.sh picks up to update blink state
            close_notification "$notif_id"
            exit 0
        fi
    fi
    
    # Fallback: just go to Slack workspace
    hyprctl dispatch workspace 4
    sleep 0.1
    hyprctl dispatch focuswindow "class:Slack"
}

main "$@"
