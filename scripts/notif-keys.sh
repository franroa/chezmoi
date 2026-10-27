#!/bin/bash
# Open notification panel and spawn wlr-which-key ready for letter keys
# The wlr-which-key popup will show available notification letters

# First open notification panel
astal -i hyprpanel -t notificationsmenu 2>/dev/null
sleep 0.1

# Check available notification letters
letters=""
for letter in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
    if grep -q "^${letter}:" /tmp/.opencode_letter_map 2>/dev/null; then
        letters="$letters$letter"
    elif grep -q "^${letter}:" /tmp/.slack_letter_map 2>/dev/null; then
        letters="$letters$letter"
    fi
done

if [[ -z "$letters" ]]; then
    notify-send "No notification keys"
    exit 0
fi

# Show hint
notify-send -t 2000 "Press letter:" "Notifications: $letters"

# Spawn wlr-which-key with initial keys to navigate to notifications
# -k option passes initial key sequence
wlr-which-key -k "n h" &
