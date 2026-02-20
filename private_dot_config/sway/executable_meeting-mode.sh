#!/bin/bash
# Meeting Mode - Optimize environment for video calls
# Usage: meeting-mode.sh [toggle|on|off|status]

STATE_FILE="/tmp/meeting_mode_active"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

is_active() {
    [[ -f "$STATE_FILE" ]]
}

notify() {
    notify-send -u normal -t 3000 -i camera-web "Meeting Mode" "$1"
}

enable_meeting() {
    if is_active; then
        echo -e "${YELLOW}Meeting mode is already active${NC}"
        return 0
    fi

    echo -e "${GREEN}Enabling Meeting Mode...${NC}"

    # 1. Enable DND to avoid notification popups during screen share
    dunstctl set-paused true
    echo "  - Notifications paused"

    # 2. Stop any playing media
    playerctl -a pause 2>/dev/null
    echo "  - Media paused"

    # 3. Kill any focus music that might be playing
    pkill -f "mpv.*focus_music" 2>/dev/null

    # 4. Set audio to optimal meeting settings
    # Unmute microphone
    pactl set-source-mute @DEFAULT_SOURCE@ 0 2>/dev/null
    # Set reasonable volume levels
    pactl set-sink-volume @DEFAULT_SINK@ 70% 2>/dev/null
    echo "  - Audio optimized (mic unmuted, volume 70%)"

    # 5. Disable screen blanking/dpms during meeting
    swaymsg "output * dpms on" 2>/dev/null
    # Inhibit idle (requires swayidle to respect inhibitors)
    systemd-inhibit --what=idle --who="Meeting Mode" --why="In a meeting" --mode=block sleep infinity &
    echo $! > /tmp/meeting_mode_inhibit_pid
    echo "  - Screen blanking disabled"

    # 6. Optional: Set a "On Air" indicator light if you have smart lights
    # curl -X PUT http://your-hue-bridge/api/.../lights/1/state -d '{"on":true,"hue":0,"sat":254}'

    # Mark as active with timestamp
    date +%s > "$STATE_FILE"

    notify "Meeting Mode ON - You're live!"
    echo -e "${GREEN}Meeting Mode is now ACTIVE${NC}"

    # Signal waybar to update
    pkill -RTMIN+9 waybar 2>/dev/null
}

disable_meeting() {
    if ! is_active; then
        echo -e "${YELLOW}Meeting mode is not active${NC}"
        return 0
    fi

    echo -e "${RED}Disabling Meeting Mode...${NC}"

    # Calculate meeting duration
    START_TIME=$(cat "$STATE_FILE" 2>/dev/null)
    if [[ -n "$START_TIME" ]]; then
        NOW=$(date +%s)
        DURATION=$((NOW - START_TIME))
        MINS=$((DURATION / 60))
        echo -e "  - Meeting lasted ${GREEN}${MINS} minutes${NC}"
    fi

    # 1. Re-enable notifications
    dunstctl set-paused false
    echo "  - Notifications resumed"

    # 2. Kill the idle inhibitor
    if [[ -f /tmp/meeting_mode_inhibit_pid ]]; then
        kill $(cat /tmp/meeting_mode_inhibit_pid) 2>/dev/null
        rm -f /tmp/meeting_mode_inhibit_pid
    fi
    echo "  - Screen blanking re-enabled"

    # 3. Mute microphone for privacy
    pactl set-source-mute @DEFAULT_SOURCE@ 1 2>/dev/null
    echo "  - Microphone muted"

    # Remove state file
    rm -f "$STATE_FILE"

    notify "Meeting Mode OFF - Great call!"
    echo -e "${RED}Meeting Mode is now INACTIVE${NC}"

    # Signal waybar to update
    pkill -RTMIN+9 waybar 2>/dev/null
}

status() {
    if is_active; then
        START_TIME=$(cat "$STATE_FILE" 2>/dev/null)
        if [[ -n "$START_TIME" ]]; then
            NOW=$(date +%s)
            DURATION=$((NOW - START_TIME))
            MINS=$((DURATION / 60))
            echo -e "${GREEN}Meeting Mode: ACTIVE${NC} (${MINS}m)"
        else
            echo -e "${GREEN}Meeting Mode: ACTIVE${NC}"
        fi
        return 0
    else
        echo -e "${RED}Meeting Mode: INACTIVE${NC}"
        return 1
    fi
}

case "${1:-toggle}" in
    on|enable|start)
        enable_meeting
        ;;
    off|disable|stop)
        disable_meeting
        ;;
    toggle)
        if is_active; then
            disable_meeting
        else
            enable_meeting
        fi
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|status]"
        exit 1
        ;;
esac
