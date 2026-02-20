#!/bin/bash
# Meeting Detector Daemon - Auto-detect when in a meeting
# Monitors for Slack calls, Google Meet, Zoom, Teams
# Usage: meeting-detector.sh [start|stop|status]

PIDFILE="/tmp/meeting_detector.pid"
LOGFILE="/tmp/meeting_detector.log"
CHECK_INTERVAL=5  # seconds

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# Check if microphone is being used by meeting apps
check_mic_usage() {
    # Get list of applications using the microphone
    local mic_users=$(pactl list source-outputs 2>/dev/null | grep -A 20 "Source Output" | grep "application.name" | cut -d'"' -f2)
    
    # Check for known meeting apps
    for app in $mic_users; do
        case "$app" in
            *[Ss]lack*|*[Zz]oom*|*[Tt]eams*|*[Ww]ebex*|*[Dd]iscord*|*[Ff]irefox*|*[Cc]hrome*|*[Cc]hromium*)
                echo "$app"
                return 0
                ;;
        esac
    done
    return 1
}

# Check for meeting windows
check_meeting_windows() {
    local windows=$(swaymsg -t get_tree 2>/dev/null)
    
    # Check for Google Meet
    if echo "$windows" | grep -qi "meet.google.com"; then
        echo "Google Meet"
        return 0
    fi
    
    # Check for Zoom
    if echo "$windows" | grep -qi '"app_id":"zoom"'; then
        echo "Zoom"
        return 0
    fi
    
    # Check for Microsoft Teams
    if echo "$windows" | grep -qi "teams.microsoft.com\|teams.live.com"; then
        echo "Microsoft Teams"
        return 0
    fi
    
    # Check for Slack huddle/call (window title contains "Huddle" or "Call")
    if echo "$windows" | grep -qi '"class":"Slack".*[Hh]uddle\|[Hh]uddle.*"class":"Slack"'; then
        echo "Slack Huddle"
        return 0
    fi
    
    # Check Slack call via title
    if echo "$windows" | jq -r '.. | select(.class? == "Slack" or .app_id? == "Slack") | .name // empty' 2>/dev/null | grep -qiE "call|huddle|screen share"; then
        echo "Slack Call"
        return 0
    fi
    
    return 1
}

# Main detection loop
detector_loop() {
    local was_in_meeting=false
    local current_app=""
    
    log "Meeting detector started"
    
    while true; do
        local meeting_app=""
        
        # Check microphone first (most reliable indicator)
        meeting_app=$(check_mic_usage)
        
        # If no mic usage, check window titles
        if [[ -z "$meeting_app" ]]; then
            meeting_app=$(check_meeting_windows)
        fi
        
        if [[ -n "$meeting_app" ]]; then
            if [[ "$was_in_meeting" == "false" ]]; then
                log "Meeting detected: $meeting_app"
                ~/.config/sway/meeting-mode.sh on >/dev/null 2>&1
                was_in_meeting=true
                current_app="$meeting_app"
            fi
        else
            if [[ "$was_in_meeting" == "true" ]]; then
                log "Meeting ended: $current_app"
                ~/.config/sway/meeting-mode.sh off >/dev/null 2>&1
                was_in_meeting=false
                current_app=""
            fi
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

start_daemon() {
    if [[ -f "$PIDFILE" ]] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
        echo "Meeting detector is already running (PID: $(cat $PIDFILE))"
        return 1
    fi
    
    # Start in background
    detector_loop &
    local pid=$!
    echo $pid > "$PIDFILE"
    echo "Meeting detector started (PID: $pid)"
    log "Daemon started with PID $pid"
}

stop_daemon() {
    if [[ -f "$PIDFILE" ]]; then
        local pid=$(cat "$PIDFILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PIDFILE"
            echo "Meeting detector stopped"
            log "Daemon stopped"
            
            # Also disable meeting mode if it was auto-enabled
            if [[ -f /tmp/meeting_mode_active ]]; then
                ~/.config/sway/meeting-mode.sh off >/dev/null 2>&1
            fi
        else
            rm -f "$PIDFILE"
            echo "Meeting detector was not running (stale pidfile removed)"
        fi
    else
        echo "Meeting detector is not running"
    fi
}

status_daemon() {
    if [[ -f "$PIDFILE" ]] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
        echo "Meeting detector is running (PID: $(cat $PIDFILE))"
        
        # Show recent log entries
        if [[ -f "$LOGFILE" ]]; then
            echo ""
            echo "Recent activity:"
            tail -5 "$LOGFILE"
        fi
        return 0
    else
        echo "Meeting detector is not running"
        return 1
    fi
}

case "${1:-start}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    status)
        status_daemon
        ;;
    *)
        echo "Usage: $0 [start|stop|restart|status]"
        exit 1
        ;;
esac
