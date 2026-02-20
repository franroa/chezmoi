#!/bin/bash
# Focus Mode - Minimize distractions for deep work
# Usage: focus-mode.sh [toggle|on|off|status]

STATE_FILE="/tmp/focus_mode_active"
LOFI_URL="https://www.youtube.com/watch?v=jfKfPfyJRdk"  # lofi hip hop radio

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

is_active() {
    [[ -f "$STATE_FILE" ]]
}

notify() {
    if ! dunstctl is-paused | grep -q "true"; then
        notify-send -u normal -t 3000 "Focus Mode" "$1"
    fi
}

enable_focus() {
    if is_active; then
        echo -e "${YELLOW}Focus mode is already active${NC}"
        return 0
    fi

    echo -e "${GREEN}Enabling Focus Mode...${NC}"

    # 1. Enable DND
    dunstctl set-paused true
    echo "  - Notifications paused"

    # 2. Switch to minimal waybar
    pkill waybar
    sleep 0.3
    waybar -c ~/.config/waybar/config-focus -s ~/.config/waybar/style-focus.css &disown
    echo "  - Waybar switched to minimal mode"

    # 3. Dim unfocused windows
    # Note: sway doesn't have built-in opacity for unfocused windows
    # We use swaymsg to set a class-based opacity via config or use inactive_opacity if supported
    # Alternative: use a separate script with swaymsg subscribe
    echo "  - Window dimming not directly supported, consider sway-fader"

    # 4. Close distracting apps
    if pgrep -f "slack" >/dev/null 2>&1; then
        # Save workspace so we can restore later
        SLACK_WS=$(swaymsg -t get_tree | jq -r '.. | select(.app_id? == "Slack" or .class? == "Slack") | .workspace // empty' 2>/dev/null | head -1)
        if [[ -n "$SLACK_WS" ]]; then
            echo "$SLACK_WS" > /tmp/focus_mode_slack_ws
        fi
        swaymsg '[class="Slack"] move scratchpad' 2>/dev/null
        swaymsg '[app_id="Slack"] move scratchpad' 2>/dev/null
        echo "  - Slack moved to scratchpad"
    fi

    # 5. Start focus music (optional - only if mpv is available)
    if command -v mpv >/dev/null 2>&1 && command -v yt-dlp >/dev/null 2>&1; then
        # Kill any existing focus music
        pkill -f "mpv.*focus_music" 2>/dev/null
        # Start lofi stream in background with low volume
        nohup mpv --no-video --volume=30 --title="focus_music" "$LOFI_URL" >/dev/null 2>&1 &
        echo "  - Focus music started (lofi hip hop)"
    else
        echo "  - Focus music skipped (mpv/yt-dlp not installed)"
    fi

    # 6. Change wallpaper to something calming (optional)
    # Uncomment and set your focus wallpaper path
    # swaymsg "output * bg /path/to/focus-wallpaper.jpg fill"

    # Mark as active
    date +%s > "$STATE_FILE"

    notify "Focus Mode enabled - time to concentrate!"
    echo -e "${GREEN}Focus Mode is now ACTIVE${NC}"
}

disable_focus() {
    if ! is_active; then
        echo -e "${YELLOW}Focus mode is not active${NC}"
        return 0
    fi

    echo -e "${RED}Disabling Focus Mode...${NC}"

    # Calculate focus duration
    START_TIME=$(cat "$STATE_FILE" 2>/dev/null)
    if [[ -n "$START_TIME" ]]; then
        NOW=$(date +%s)
        DURATION=$((NOW - START_TIME))
        MINS=$((DURATION / 60))
        echo -e "  - Focus session lasted ${GREEN}${MINS} minutes${NC}"
    fi

    # 1. Disable DND
    dunstctl set-paused false
    echo "  - Notifications resumed"

    # 2. Restore normal waybar
    pkill waybar
    sleep 0.3
    waybar &disown
    echo "  - Waybar restored to normal"

    # 3. Stop focus music
    pkill -f "mpv.*focus_music" 2>/dev/null
    echo "  - Focus music stopped"

    # 4. Restore Slack from scratchpad (optional)
    # Uncomment if you want Slack to auto-restore
    # swaymsg '[class="Slack"] scratchpad show' 2>/dev/null
    # swaymsg '[app_id="Slack"] scratchpad show' 2>/dev/null
    echo "  - Slack remains in scratchpad (use $mod+Shift+s to restore)"

    # 5. Restore wallpaper (optional)
    # Uncomment and set your normal wallpaper
    # swaymsg "output * bg /path/to/normal-wallpaper.jpg fill"

    # Remove state file
    rm -f "$STATE_FILE" /tmp/focus_mode_slack_ws

    notify "Focus Mode disabled - great session!"
    echo -e "${RED}Focus Mode is now INACTIVE${NC}"
}

status() {
    if is_active; then
        START_TIME=$(cat "$STATE_FILE" 2>/dev/null)
        if [[ -n "$START_TIME" ]]; then
            NOW=$(date +%s)
            DURATION=$((NOW - START_TIME))
            MINS=$((DURATION / 60))
            echo -e "${GREEN}Focus Mode: ACTIVE${NC} (${MINS}m)"
        else
            echo -e "${GREEN}Focus Mode: ACTIVE${NC}"
        fi
        return 0
    else
        echo -e "${RED}Focus Mode: INACTIVE${NC}"
        return 1
    fi
}

# Waybar output (for custom module)
waybar_output() {
    if is_active; then
        START_TIME=$(cat "$STATE_FILE" 2>/dev/null)
        if [[ -n "$START_TIME" ]]; then
            NOW=$(date +%s)
            DURATION=$((NOW - START_TIME))
            MINS=$((DURATION / 60))
            echo "{\"text\": \" ${MINS}m\", \"tooltip\": \"Focus Mode active - ${MINS} minutes\", \"class\": \"active\", \"alt\": \"active\"}"
        else
            echo '{"text": "󰈈", "tooltip": "Focus Mode active", "class": "active", "alt": "active"}'
        fi
    else
        echo '{"text": "󰈈", "tooltip": "Focus Mode inactive - click to enable", "class": "inactive", "alt": "inactive"}'
    fi
}

case "${1:-toggle}" in
    on|enable|start)
        enable_focus
        ;;
    off|disable|stop)
        disable_focus
        ;;
    toggle)
        if is_active; then
            disable_focus
        else
            enable_focus
        fi
        ;;
    status)
        status
        ;;
    waybar)
        waybar_output
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|status|waybar]"
        exit 1
        ;;
esac
