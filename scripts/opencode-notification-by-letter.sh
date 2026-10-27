#!/bin/bash
# Trigger OpenCode notification action by letter
# Shows a menu to pick which notification to open
# Usage: opencode-notification-by-letter.sh

TRACKER="/home/froa/.config/hypr/scripts/opencode-notification-tracker.sh"
LETTER_MAP="/tmp/.opencode_letter_map"

# Get all available letters
if [[ ! -f "$LETTER_MAP" ]] || [[ ! -s "$LETTER_MAP" ]]; then
    notify-send "OpenCode" "No active notifications"
    exit 0
fi

# Build menu options from letter map
OPTIONS=""
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        LETTER=$(echo "$line" | cut -d: -f1)
        INFO=$(echo "$line" | cut -d: -f2)
        NOTIF_ID=$(echo "$INFO" | cut -d'|' -f1)
        CWD=$(echo "$INFO" | cut -d'|' -f2)
        SESSION=$(echo "$INFO" | cut -d'|' -f3)
        
        # Get just the project name from CWD
        PROJECT=$(basename "$CWD" 2>/dev/null)
        
        OPTIONS="$OPTIONS$LETTER: $PROJECT ($SESSION)\n"
    fi
done < "$LETTER_MAP"

# Show rofi menu
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "OpenCode notification:")

if [[ -z "$CHOICE" ]]; then
    exit 0
fi

# Extract letter from choice
LETTER=$(echo "$CHOICE" | cut -d: -f1)

# Find the notification ID for this letter
NOTIF_INFO=$(grep "^${LETTER}:" "$LETTER_MAP" 2>/dev/null | head -1)

if [[ -z "$NOTIF_INFO" ]]; then
    echo "No notification found for letter: $LETTER"
    exit 1
fi

# Parse: letter:notifId|cwd|sessionName
NOTIF_ID=$(echo "$NOTIF_INFO" | cut -d: -f2 | cut -d'|' -f1)
CWD=$(echo "$NOTIF_INFO" | cut -d'|' -f2)
SESSION_NAME=$(echo "$NOTIF_INFO" | cut -d'|' -f3)

echo "Opening: letter=$LETTER, id=$NOTIF_ID, cwd=$CWD, session=$SESSION_NAME"

# Remove from tracker
$TRACKER remove "$NOTIF_ID" 2>/dev/null

# Release the letter
USED=$(cat /tmp/.opencode_letters 2>/dev/null | tr ',' '\n' | grep -v "^$LETTER$" | tr '\n' ',' | sed 's/,$//')
echo "$USED" > /tmp/.opencode_letters

# Remove from letter map
sed -i "/^${LETTER}:/d" "$LETTER_MAP"

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
