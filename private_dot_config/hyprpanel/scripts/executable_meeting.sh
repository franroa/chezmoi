#!/bin/bash
# Meeting Detection Script for HyprPanel
# Auto-detects Zoom, Slack, Google Meet calls

MEETING_STATE="/tmp/meeting-active"
MEETING_APP="/tmp/meeting-app"

# Meeting app patterns
detect_meeting() {
    local app=""
    local title=""
    
    # Check for active audio input (microphone) from meeting apps
    local active_sources
    active_sources=$(pactl list source-outputs 2>/dev/null)
    
    # Check Zoom
    if echo "$active_sources" | grep -qi "zoom"; then
        app="Zoom"
    # Check Slack
    elif echo "$active_sources" | grep -qi "slack"; then
        app="Slack"
    # Check Chrome/Firefox (Google Meet)
    elif echo "$active_sources" | grep -qiE "chrome|chromium|firefox"; then
        # Verify it's actually Google Meet via window title
        if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.title | test("Meet -|Google Meet"; "i"))' > /dev/null 2>&1; then
            app="Google Meet"
        fi
    fi
    
    # Fallback: Check window titles
    if [[ -z "$app" ]]; then
        if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "zoom" and .title | test("Meeting|Zoom Meeting"; "i"))' > /dev/null 2>&1; then
            app="Zoom"
        elif hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "Slack" and .title | test("Huddle|Call"; "i"))' > /dev/null 2>&1; then
            app="Slack Huddle"
        elif hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.title | test("Meet -|Google Meet"; "i"))' > /dev/null 2>&1; then
            app="Google Meet"
        fi
    fi
    
    echo "$app"
}

enter_meeting_mode() {
    local app="$1"
    echo "$app" > "$MEETING_APP"
    touch "$MEETING_STATE"
    
    # Enable DND
    swaync-client -d on 2>/dev/null || true
    
    # Inhibit idle
    if pgrep -x hypridle > /dev/null; then
        pkill -STOP hypridle 2>/dev/null || true
    fi
    
    notify-send -u low -i video-display "Meeting Started" "$app - DND enabled"
}

exit_meeting_mode() {
    local was_app=""
    [[ -f "$MEETING_APP" ]] && was_app=$(cat "$MEETING_APP")
    
    rm -f "$MEETING_STATE" "$MEETING_APP"
    
    # Disable DND
    swaync-client -d off 2>/dev/null || true
    
    # Resume idle
    if pgrep -x hypridle > /dev/null; then
        pkill -CONT hypridle 2>/dev/null || true
    fi
    
    notify-send -u low -i video-display "Meeting Ended" "${was_app:-Meeting} - DND disabled"
}

get_status() {
    if [[ -f "$MEETING_STATE" ]]; then
        local app="Meeting"
        [[ -f "$MEETING_APP" ]] && app=$(cat "$MEETING_APP")
        
        # HyprPanel format: output text for display
        echo "{\"text\": \"$app\", \"tooltip\": \"In $app - DND Active\\nClick to end meeting mode\"}"
    else
        # Output nothing - hideOnEmpty will hide the module
        echo ""
    fi
}

toggle() {
    if [[ -f "$MEETING_STATE" ]]; then
        exit_meeting_mode
    else
        enter_meeting_mode "Manual"
    fi
}

daemon() {
    local was_in_meeting=false
    local last_app=""
    
    while true; do
        local current_app
        current_app=$(detect_meeting)
        
        if [[ -n "$current_app" ]]; then
            if [[ "$was_in_meeting" == false ]]; then
                enter_meeting_mode "$current_app"
                was_in_meeting=true
                last_app="$current_app"
            elif [[ "$current_app" != "$last_app" ]]; then
                # App changed
                echo "$current_app" > "$MEETING_APP"
                last_app="$current_app"
            fi
        else
            if [[ "$was_in_meeting" == true ]]; then
                exit_meeting_mode
                was_in_meeting=false
                last_app=""
            fi
        fi
        
        sleep 3
    done
}

case "$1" in
    ""|status)
        get_status
        ;;
    toggle)
        toggle
        ;;
    daemon)
        daemon
        ;;
    check)
        app=$(detect_meeting)
        if [[ -n "$app" ]]; then
            echo "$app"
            exit 0
        else
            echo "No meeting"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {status|toggle|daemon|check}"
        exit 1
        ;;
esac
