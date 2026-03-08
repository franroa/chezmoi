#!/bin/bash
# Open the latest OpenCode notification
# Called by notification action button click

TRACKER="/home/froa/.config/hypr/scripts/opencode-notification-tracker.sh"
LETTER_MAP="/tmp/.opencode_letter_map"

# Check if there are any notifications
if [[ ! -f "$LETTER_MAP" ]] || [[ ! -s "$LETTER_MAP" ]]; then
    notify-send "OpenCode" "No active notifications"
    exit 0
fi

# Get the latest notification (first line = oldest, last line = newest)
# We'll use the last line as it's the most recent
LATEST_NOTIF=$(tail -1 "$LETTER_MAP")

if [[ -z "$LATEST_NOTIF" ]]; then
    notify-send "OpenCode" "No active notifications"
    exit 0
fi

# Parse: letter:notifId|cwd|sessionName
LETTER=$(echo "$LATEST_NOTIF" | cut -d: -f1)
NOTIF_INFO=$(echo "$LATEST_NOTIF" | cut -d: -f2)
NOTIF_ID=$(echo "$NOTIF_INFO" | cut -d'|' -f1)
CWD=$(echo "$NOTIF_INFO" | cut -d'|' -f2)
SESSION_NAME=$(echo "$NOTIF_INFO" | cut -d'|' -f3)

echo "Opening latest: letter=$LETTER, id=$NOTIF_ID, cwd=$CWD, session=$SESSION_NAME"

# Remove from tracker
$TRACKER remove "$NOTIF_ID" 2>/dev/null

# Release the letter
if [[ -n "$LETTER" ]]; then
    USED=$(cat /tmp/.opencode_letters 2>/dev/null | tr ',' '\n' | grep -v "^$LETTER$" | tr '\n' ',' | sed 's/,$//')
    echo "$USED" > /tmp/.opencode_letters
    
    # Remove from letter map
    sed -i "/^${LETTER}:/d" "$LETTER_MAP"
fi

# Close the notification
gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.CloseNotification \
    "$NOTIF_ID" 2>/dev/null

# Open the session
if [[ -n "$CWD" && -n "$SESSION_NAME" ]]; then
    /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$CWD" "$SESSION_NAME"
else
    echo "Missing cwd or session name"
    exit 1
fi
