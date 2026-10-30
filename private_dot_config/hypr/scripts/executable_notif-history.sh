#!/bin/bash
source "$HOME/.config/hypr/scripts/hypr-lua.sh"
# notif-history.sh - Show notification history in rofi

NOTIFS=$(dunstctl history 2>/dev/null | jq -r '.data[][] | "\(.appname.data)\t\(.summary.data)\t\(.body.data // "")"' 2>/dev/null | head -20)

if [ -z "$NOTIFS" ]; then
    rofi -e "No notifications in history"
    exit 0
fi

# Show in rofi
SELECTION=$(echo "$NOTIFS" | rofi -dmenu -i -p "Notifications" \
    -format "s" \
    -kb-custom-1 "Alt+v" -kb-custom-2 "Alt+d")

if [ -z "$SELECTION" ]; then
    exit 0
fi

# Get the key pressed
KEY=$?

# Extract appname from selection
APP=$(echo "$SELECTION" | cut -f1)

if [ "$KEY" -eq 10 ]; then
    # Alt+v - view (focus app)
    case "${APP}" in
        Slack)
            hl_focus_window "class:Slack" 2>/dev/null
            ;;
        Discord)
            hl_focus_window "class:Discord" 2>/dev/null
            ;;
        *)
            hl_focus_window "class:$APP" 2>/dev/null
            ;;
    esac
elif [ "$KEY" -eq 11 ]; then
    # Alt+d - dismiss
    dunstctl clear
fi
