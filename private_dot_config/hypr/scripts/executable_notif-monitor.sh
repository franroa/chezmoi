#!/bin/bash
# Unified notification monitor for HyprPanel
# Tracks Slack and OpenCode notifications

SLACK_STATE_DIR="/tmp/slack_notifications_$USER"
OPENCODE_STATE_DIR="/tmp/opencode_notifications_$USER"
GENERATE_SCRIPT="$HOME/.config/hyprpanel/scripts/generate-modules-scss.sh"
LOCK_FILE="/tmp/notif-monitor-${USER}.lock"

# Slack deep-link correlation: Slack's browser.log records team/channel/msg per
# notification; we turn those into slack:// deep links so clicking ANY queued
# notification navigates reliably (Slack only honours ActionInvoked for its
# newest notification, so the D-Bus re-emit path fails for older ones).
SLACK_LOG="$HOME/.config/Slack/logs/default/browser.log"
SLACK_DEEPLINK_QUEUE="$SLACK_STATE_DIR/.deeplink_queue"
SLACK_DEEPLINK_LOCK="$SLACK_STATE_DIR/.deeplink_lock"
SLACK_DEEPLINK_TTL=5   # seconds; stale queue entries are flushed (self-heals desync)

mkdir -p "$SLACK_STATE_DIR" "$OPENCODE_STATE_DIR"

# --- Shared functions ---
get_slack_count() { find "$SLACK_STATE_DIR" -name "*.notif" 2>/dev/null | wc -l; }
get_opencode_count() { find "$OPENCODE_STATE_DIR" -name "*.notif" 2>/dev/null | wc -l; }

update_blink() {
    local slack_count=$(get_slack_count)
    local opencode_count=$(get_opencode_count)
    [[ "$slack_count" -gt 0 ]] && echo "$slack_count" > "/tmp/.slack_unread_$USER" || rm -f "/tmp/.slack_unread_$USER"
    [[ "$opencode_count" -gt 0 ]] && echo "$opencode_count" > "/tmp/.opencode_unread_$USER" || rm -f "/tmp/.opencode_unread_$USER"
    [[ -x "$GENERATE_SCRIPT" ]] && "$GENERATE_SCRIPT" &
}

# --- Slack functions ---
add_slack_notification() {
    local id="$1" source="$2"
    echo "$source" > "$SLACK_STATE_DIR/${id}.notif"
    update_blink
}
remove_slack_notification() {
    local id="$1"
    rm -f "$SLACK_STATE_DIR/${id}.notif" "$SLACK_STATE_DIR/${id}.url"
    update_blink
}

# Tail Slack's browser.log and enqueue a deep link for every NEW_NOTIFICATION.
# Each queue entry is "epoch|url"; entries are consumed in arrival order by
# pop_slack_deeplink when the matching D-Bus Notified signal arrives.
slack_deeplink_tailer() {
    while [[ ! -f "$SLACK_LOG" ]]; do sleep 5; done
    tail -F -n0 "$SLACK_LOG" 2>/dev/null | while IFS= read -r line; do
        [[ "$line" == *"Store: NEW_NOTIFICATION"* ]] || continue
        local team="" chan="" msg="" thread="" l count=0
        while IFS= read -r l; do
            count=$((count + 1)); [[ $count -gt 40 ]] && break
            case "$l" in
                *'"teamId":'*)    team=$(printf '%s' "$l" | grep -oP '"teamId":\s*"\K[^"]+') ;;
                *'"channel":'*)   chan=$(printf '%s' "$l" | grep -oP '"channel":\s*"\K[^"]+') ;;
                *'"msg":'*)       msg=$(printf '%s' "$l" | grep -oP '"msg":\s*"\K[^"]+') ;;
                *'"thread_ts":'*) thread=$(printf '%s' "$l" | grep -oP '"thread_ts":\s*"\K[^"]+') ;;
            esac
            [[ "$l" == "}" ]] && break
        done
        [[ -z "$team" || -z "$chan" ]] && continue
        local url="slack://channel?team=${team}&id=${chan}"
        [[ -n "$msg" ]] && url="${url}&message=${msg}"
        # thread reply: thread_ts opens the thread view; message highlights the reply
        [[ -n "$thread" ]] && url="${url}&thread_ts=${thread}"
        ( flock 8; printf '%s|%s\n' "$(date +%s)" "$url" >> "$SLACK_DEEPLINK_QUEUE" ) 8>"$SLACK_DEEPLINK_LOCK"
    done
}

# Consume the oldest fresh deep link; drop entries older than TTL (self-healing).
pop_slack_deeplink() {
    (
        flock 8
        [[ -s "$SLACK_DEEPLINK_QUEUE" ]] || exit 0
        local now picked="" ts url tmp
        now=$(date +%s)
        tmp=$(mktemp)
        while IFS='|' read -r ts url; do
            [[ -z "$ts" || -z "$url" ]] && continue
            (( now - ts > SLACK_DEEPLINK_TTL )) && continue   # stale: drop
            if [[ -z "$picked" ]]; then
                picked="$url"                                  # consume oldest fresh
            else
                printf '%s|%s\n' "$ts" "$url" >> "$tmp"         # keep the rest
            fi
        done < "$SLACK_DEEPLINK_QUEUE"
        mv "$tmp" "$SLACK_DEEPLINK_QUEUE"
        printf '%s' "$picked"
    ) 8>"$SLACK_DEEPLINK_LOCK"
}
slack_status() {
    local count=$(get_slack_count)
    if [[ "$count" -gt 0 ]]; then
        local sources=$(cat "$SLACK_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}' | paste -sd ',' -)
        echo "{\"text\": \"$count\", \"alt\": \"unread\", \"tooltip\": \"Slack - $count unread | $sources\"}"
    else
        echo "{\"text\": \"\", \"alt\": \"none\", \"tooltip\": \"Slack\"}"
    fi
}
slack_sources() {
    local count=$(get_slack_count)
    if [[ "$count" -eq 0 ]]; then
        notify-send "Slack" "No unread notifications"
        return
    fi
    local sources=$(cat "$SLACK_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}')
    notify-send "Slack - $count unread" "$sources"
}

# --- OpenCode functions ---
add_opencode_notification() {
    local id="$1" cwd="$2" session="$3"
    echo "${cwd}|${session}" > "$OPENCODE_STATE_DIR/${id}.notif"
    update_blink
}
remove_opencode_notification() {
    local id="$1"
    rm -f "$OPENCODE_STATE_DIR/${id}.notif"
    update_blink
}
opencode_status() {
    local count=$(get_opencode_count)
    if [[ "$count" -gt 0 ]]; then
        local sources=$(cat "$OPENCODE_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}' | paste -sd ',' -)
        echo "{\"text\": \"$count\", \"alt\": \"unread\", \"tooltip\": \"OpenCode - $count unread | $sources\"}"
    else
        echo "{\"text\": \"\", \"alt\": \"none\", \"tooltip\": \"OpenCode\"}"
    fi
}
opencode_sources() {
    local count=$(get_opencode_count)
    if [[ "$count" -eq 0 ]]; then
        notify-send "OpenCode" "No unread notifications"
        return
    fi
    local sources=$(cat "$OPENCODE_STATE_DIR"/*.notif 2>/dev/null | sort | uniq -c | awk '{print $2 ": " $1}')
    notify-send "OpenCode - $count unread" "$sources"
}

# --- Slack focus + navigation ---
# Navigate Slack to the message referenced by the stored action_id, then bring
# workspace 4 (where Slack lives) to focus.  Called from the ActionInvoked handler
# so slack-action-focus.sh can do the same without duplication.
focus_and_navigate_slack() {
    local notif_id="$1"
    local action_id="$2"  # captured before sleep to avoid file-deletion race

    if [[ "$action_id" =~ ^(slack://|https://) ]]; then
        xdg-open "$action_id" 2>/dev/null
    fi

    hyprctl dispatch workspace 4 2>/dev/null
    sleep 0.15
    hyprctl dispatch focuswindow "class:slack" 2>/dev/null
}

# --- Unified monitor ---
monitor() {
    # pending_app is set when we see member=Notify + a known app name.
    # The real notification ID comes back in the Notified signal, not in the Notify args
    # (uint32 in Notify args is replaces_id, not the assigned ID).
    pending_app=""

    dbus-monitor "interface='org.freedesktop.Notifications'" 2>/dev/null | \
    while IFS= read -r line; do

        # New Notify call — reset pending app
        if [[ "$line" == *"member=Notify"* ]]; then
            pending_app=""
            continue
        fi

        # Detect app name in the Notify call arguments
        if [[ "$line" == *'string "Slack"'* ]]; then
            pending_app="slack"
            continue
        fi
        if [[ "$line" == *'string "OpenCode"'* ]]; then
            pending_app="opencode"
            continue
        fi

        # Notified signal carries the real assigned notification ID
        if [[ "$line" == *"member=Notified"* ]]; then
            # Next non-blank line is: "   uint32 <id>"
            while IFS= read -r id_line; do
                [[ -z "${id_line// }" ]] && continue
                notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
                [[ -z "$notif_id" ]] && break
                if [[ "$pending_app" == "slack" ]]; then
                    # Fetch full notification JSON to get actual action ID
                    local action_id="default"
                    local full_json
                    full_json=$(busctl --user call org.freedesktop.Notifications \
                        /org/freedesktop/Notifications org.freedesktop.Notifications \
                        GetNotificationJson u "$notif_id" 2>/dev/null)
                    if [[ -n "$full_json" ]]; then
                        # Extract first action id from JSON: "actions":[{"id":"foo",...}]
                        local extracted
                        extracted=$(echo "$full_json" | python3 -c \
                            "import json,sys; s=sys.stdin.read().strip(); \
                            d=json.loads(json.loads(s[2:])); \
                            acts=d.get('actions',[]); print(acts[0]['id'] if acts else 'default')" 2>/dev/null)
                        [[ -n "$extracted" ]] && action_id="$extracted"
                    fi
                    add_slack_notification "$notif_id" "$action_id"
                    # Correlate this notification with the deep link the tailer
                    # extracted from browser.log (arrival order). Retry briefly:
                    # the log line may land a few ms after the Notified signal.
                    local url="" tries=0
                    while [[ -z "$url" && $tries -lt 5 ]]; do
                        url=$(pop_slack_deeplink)
                        [[ -n "$url" ]] && break
                        sleep 0.1; tries=$((tries + 1))
                    done
                    [[ -n "$url" ]] && printf '%s' "$url" > "$SLACK_STATE_DIR/${notif_id}.url"
                elif [[ "$pending_app" == "opencode" ]]; then
                    add_opencode_notification "$notif_id" "/tmp" "default"
                fi
                pending_app=""
                break
            done
            continue
        fi

        # Notification closed — remove from whichever state dir owns it
        if [[ "$line" == *"member=NotificationClosed"* ]]; then
            while IFS= read -r id_line; do
                [[ -z "${id_line// }" ]] && continue
                notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
                [[ -z "$notif_id" ]] && break
                [[ -f "$SLACK_STATE_DIR/${notif_id}.notif" ]]    && remove_slack_notification "$notif_id"
                [[ -f "$OPENCODE_STATE_DIR/${notif_id}.notif" ]] && remove_opencode_notification "$notif_id"
                break
            done
            continue
        fi

        # Action invoked — navigate Slack to the source message and focus it.
        # This runs alongside slack-action-focus.sh; both check the .notif file
        # before NotificationClosed can delete it (signals arrive in order).
        if [[ "$line" == *"member=ActionInvoked"* ]]; then
            while IFS= read -r id_line; do
                [[ -z "${id_line// }" ]] && continue
                notif_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
                [[ -z "$notif_id" ]] && break
                if [[ -f "$SLACK_STATE_DIR/${notif_id}.notif" ]]; then
                    # Capture action_id NOW — NotificationClosed deletes the file
                    # during the sleep below, causing a race if read later.
                    action_id=$(cat "$SLACK_STATE_DIR/${notif_id}.notif" 2>/dev/null)
                    (sleep 0.3 && focus_and_navigate_slack "$notif_id" "$action_id") &
                fi
                break
            done
            continue
        fi

    done
}

# --- Commands ---
case "${1:-}" in
    monitor)
        exec 9>"$LOCK_FILE"
        if ! flock -n 9; then
            exit 0
        fi
        : > "$SLACK_DEEPLINK_QUEUE"          # start with a clean queue
        slack_deeplink_tailer &              # feed deep links from Slack's log
        SLACK_TAILER_PID=$!
        trap 'kill "$SLACK_TAILER_PID" 2>/dev/null' EXIT
        monitor
        ;;
    slack-status)       slack_status ;;
    slack-sources)     slack_sources ;;
    slack-clear)
        rm -f "$SLACK_STATE_DIR"/*.notif; update_blink ;;
    opencode-status)    opencode_status ;;
    opencode-sources)  opencode_sources ;;
    opencode-clear)
        rm -f "$OPENCODE_STATE_DIR"/*.notif; update_blink ;;
    *) 
        echo "Usage: $0 {monitor|slack-status|slack-sources|slack-clear|opencode-status|opencode-sources|opencode-clear}"
        ;;
esac
