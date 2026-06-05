#!/bin/bash
# Called by hyprpanel when a Slack notification action is clicked.
#
# Preferred path: open the slack:// deep link captured from Slack's browser.log
# by notif-monitor.sh (stored as <id>.url). This navigates Slack to the source
# message for ANY notification, including older queued ones.
#
# Fallback path (no deep link available): re-emit the D-Bus ActionInvoked signal.
# Slack only honours this for its most-recent notification, so it is unreliable
# for queued notifications — hence the deep-link path above.
NOTIF_ID="$1"
ACTION_ID="${2:-default}"

STATE_DIR="/tmp/slack_notifications_${USER}"
URL_FILE="${STATE_DIR}/${NOTIF_ID}.url"
LOG=/tmp/slack-nav.log
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

# Hide any pypr scratchpad first so focusing Slack doesn't bounce.
~/.local/bin/pypr hide "*" 2>/dev/null

if [[ -f "$URL_FILE" ]]; then
    url=$(cat "$URL_FILE")
    log "click notifId=$NOTIF_ID deeplink=$url"
    # Slack handles the deep link by navigating AND raising its own window
    # (Hyprland honours the xdg-activation token from xdg-open), switching to
    # workspace 4 itself. Do NOT also dispatch workspace/focus here, or it
    # switches to workspace 4 twice.
    xdg-open "$url" 2>>"$LOG"
else
    log "click notifId=$NOTIF_ID no deeplink, fallback EmitActionInvoked action=$ACTION_ID"
    busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
        org.freedesktop.Notifications EmitActionInvoked us "$NOTIF_ID" "$ACTION_ID" 2>>"$LOG"
    # ActionInvoked-based activation is unreliable on Hyprland 0.55+, so bring
    # Slack into view manually for the fallback path only.
    sleep 0.3
    hyprctl dispatch workspace 4 2>>"$LOG"
    sleep 0.15
    hyprctl dispatch focuswindow class:slack 2>>"$LOG"
fi
