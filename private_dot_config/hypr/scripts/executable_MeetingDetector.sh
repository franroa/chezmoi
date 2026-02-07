#!/bin/bash
# Meeting Detection Daemon
# Detects active meetings (Zoom, Slack, Google Meet) and manages DND/idle inhibit

MEETING_LOCK="/tmp/meeting-detector.lock"
MEETING_STATE="/tmp/meeting-active"
CHECK_INTERVAL=5

# Meeting app patterns (process names and window classes)
MEETING_PROCESSES=(
    "zoom"
    "slack"
    "chrome.*meet.google.com"
    "firefox.*meet.google.com"
    "chromium.*meet.google.com"
    "Google Meet"
)

# Audio sink patterns that indicate active call
AUDIO_PATTERNS=(
    "Zoom"
    "ZOOM"
    "Slack"
    "slack"
    "Google Chrome"
    "Chromium"
    "Firefox"
    "Meet"
)

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

is_meeting_active() {
    # Method 1: Check for active audio streams from meeting apps
    local active_streams
    active_streams=$(pactl list sink-inputs 2>/dev/null | grep -iE "application.name|media.name" | tr '\n' ' ')
    
    for pattern in "${AUDIO_PATTERNS[@]}"; do
        if echo "$active_streams" | grep -qi "$pattern"; then
            # Verify the app is actually in a meeting (has active audio input too)
            local has_input
            has_input=$(pactl list source-outputs 2>/dev/null | grep -iE "application.name|media.name" | tr '\n' ' ')
            if echo "$has_input" | grep -qi "$pattern"; then
                return 0
            fi
        fi
    done
    
    # Method 2: Check for Zoom meeting window
    if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "zoom" and .title | test("Meeting|Zoom Meeting"; "i"))' > /dev/null 2>&1; then
        return 0
    fi
    
    # Method 3: Check for Slack huddle
    if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "Slack" and .title | test("Huddle|Call"; "i"))' > /dev/null 2>&1; then
        return 0
    fi
    
    # Method 4: Check for Google Meet tab (via window title)
    if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.title | test("Meet -|Google Meet"; "i"))' > /dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

enter_meeting_mode() {
    log "Entering meeting mode"
    touch "$MEETING_STATE"
    
    # Enable DND
    swaync-client -d on 2>/dev/null || true
    
    # Inhibit idle (hypridle)
    if command -v hypridle &>/dev/null; then
        pkill -STOP hypridle 2>/dev/null || true
    fi
    
    # Notify
    notify-send -u low -i video-display "Meeting Mode" "DND enabled, idle inhibited"
}

exit_meeting_mode() {
    log "Exiting meeting mode"
    rm -f "$MEETING_STATE"
    
    # Disable DND
    swaync-client -d off 2>/dev/null || true
    
    # Resume idle
    if command -v hypridle &>/dev/null; then
        pkill -CONT hypridle 2>/dev/null || true
    fi
    
    # Notify
    notify-send -u low -i video-display "Meeting Ended" "DND disabled, idle resumed"
}

get_status() {
    if [[ -f "$MEETING_STATE" ]]; then
        echo '{"text": "󰤙", "tooltip": "In Meeting - DND Active", "class": "meeting"}'
    else
        echo '{"text": "", "tooltip": "No active meeting", "class": "idle"}'
    fi
}

daemon() {
    # Prevent multiple instances
    if [[ -f "$MEETING_LOCK" ]]; then
        pid=$(cat "$MEETING_LOCK")
        if kill -0 "$pid" 2>/dev/null; then
            log "Daemon already running (PID: $pid)"
            exit 1
        fi
    fi
    
    echo $$ > "$MEETING_LOCK"
    trap "rm -f $MEETING_LOCK $MEETING_STATE; exit" EXIT INT TERM
    
    log "Meeting detector daemon started"
    
    local was_in_meeting=false
    
    while true; do
        if is_meeting_active; then
            if [[ "$was_in_meeting" == false ]]; then
                enter_meeting_mode
                was_in_meeting=true
            fi
        else
            if [[ "$was_in_meeting" == true ]]; then
                exit_meeting_mode
                was_in_meeting=false
            fi
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

toggle_manual() {
    if [[ -f "$MEETING_STATE" ]]; then
        exit_meeting_mode
    else
        enter_meeting_mode
    fi
}

case "$1" in
    daemon)
        daemon
        ;;
    status)
        get_status
        ;;
    toggle)
        toggle_manual
        ;;
    check)
        if is_meeting_active; then
            echo "Meeting detected"
            exit 0
        else
            echo "No meeting"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {daemon|status|toggle|check}"
        echo ""
        echo "  daemon  - Run as background daemon (auto-detect meetings)"
        echo "  status  - Get current status (for Waybar)"
        echo "  toggle  - Manually toggle meeting mode"
        echo "  check   - Check if meeting is currently active"
        exit 1
        ;;
esac
