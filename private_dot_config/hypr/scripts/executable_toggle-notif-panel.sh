#!/bin/bash
# Toggle notification panel and show hint

# Toggle via swaync-client
swaync-client -t -sw 2>/dev/null

# Show notification hint
notify-send -r 9998 "Notification Panel" "OpenCode: SUPER+[letter] | Slack: SUPER+[letter]" -i notification-message-iminstant
