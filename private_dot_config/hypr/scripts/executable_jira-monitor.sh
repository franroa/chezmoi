#!/bin/bash
# Jira notification monitor for HyprPanel
# Polls Jira Cloud API for:
#   - Issues assigned to you (recently updated)
#   - @mentions in comments
#   - New comments on issues you own/reported
#   - Status transitions on your issues
#   - Updates on issues you watch
#
# Setup:
#   ~/.config/jira-credentials:
#     JIRA_URL="https://yourcompany.atlassian.net"
#     JIRA_EMAIL="you@company.com"
#     JIRA_API_TOKEN="your-api-token"

NOTIF_STATE_DIR="/tmp/jira_notifications_$USER"
NOTIF_COUNTER_FILE="/tmp/.jira_unread_$USER"
NOTIF_APP_NAME="Jira"
CREDS_FILE="$HOME/.config/jira-credentials"
SEEN_DIR="/tmp/.jira_seen_$USER"
POLL_INTERVAL=60

source /home/froa/.config/hypr/scripts/notification-tracker-lib.sh

mkdir -p "$SEEN_DIR"

# ---------------------------------------------------------------------------
# Send a desktop notification and record the dbus ID → internal notif ID map
# Usage: send_notif <notif_id> [notify-send args...]
# All args after <notif_id> are passed verbatim to notify-send.
# ---------------------------------------------------------------------------

send_notif() {
    local notif_id="$1"; shift
    local dbus_id
    dbus_id=$(notify-send --print-id "$@" 2>/dev/null)
    if [[ -n "$dbus_id" && "$dbus_id" =~ ^[0-9]+$ ]]; then
        echo "$notif_id" > "$NOTIF_STATE_DIR/dbus_${dbus_id}"
    fi
}

# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------

load_credentials() {
    if [[ ! -f "$CREDS_FILE" ]]; then
        notify-send -u critical "Jira" "Please configure credentials in:\n$CREDS_FILE"
        exit 1
    fi
    eval "$(grep -v '^#' "$CREDS_FILE" | grep '=')"
    # Support both JIRA_URL and JIRA_DOMAIN variable names
    if [[ -z "${JIRA_URL:-}" && -n "${JIRA_DOMAIN:-}" ]]; then
        JIRA_URL="https://${JIRA_DOMAIN}"
    fi
    if [[ "${JIRA_API_TOKEN:-}" == "your-api-token" || -z "${JIRA_API_TOKEN:-}" ]]; then
        notify-send -u normal "Jira" "Please configure your Jira API token in:\n$CREDS_FILE"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# API helper
# ---------------------------------------------------------------------------

jira_api() {
    local endpoint="$1"
    local response http_code
    response=$(curl -s -w "\n__HTTP_CODE__:%{http_code}" --connect-timeout 5 --max-time 15 \
         -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
         -H "Accept: application/json" \
         "${JIRA_URL}/rest/api/3/${endpoint}" 2>/dev/null)
    http_code=$(echo "$response" | grep -oP '__HTTP_CODE__:\K[0-9]+' || echo "000")
    response=$(echo "$response" | sed 's/__HTTP_CODE__:[0-9]*$//')
    # Log non-JSON responses for debugging
    if [[ -n "$response" ]] && ! echo "$response" | jq empty 2>/dev/null; then
        echo "[jira-monitor] HTTP $http_code non-JSON response for $endpoint: ${response:0:200}" >> /tmp/jira-monitor-debug.log
        echo ""
        return 1
    fi
    # Detect API-level errors returned as valid JSON (e.g. HTTP 410 with errorMessages)
    if [[ -n "$response" ]] && echo "$response" | jq -e '.errorMessages | length > 0' >/dev/null 2>&1; then
        local err_msg
        err_msg=$(echo "$response" | jq -r '.errorMessages[0] // "unknown error"')
        echo "[jira-monitor] HTTP $http_code API error for $endpoint: $err_msg" >> /tmp/jira-monitor-debug.log
        echo ""
        return 1
    fi
    echo "$response"
}

jira_api_post() {
    local endpoint="$1"
    local body="$2"
    curl -s --connect-timeout 5 --max-time 15 \
         -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
         -H "Accept: application/json" \
         -H "Content-Type: application/json" \
         -X POST \
         -d "$body" \
         "${JIRA_URL}/rest/api/3/${endpoint}" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Seen-state helpers (track last-checked timestamp per category)
# ---------------------------------------------------------------------------

seen_get() {
    local key="$1"
    local file="$SEEN_DIR/${key}"
    [[ -f "$file" ]] && cat "$file" || echo ""
}

seen_set() {
    local key="$1"
    local value="$2"
    echo "$value" > "$SEEN_DIR/${key}"
}

# Return current UTC time in Jira-compatible ISO-8601 format (e.g. 2026-03-17T10:00:00.000+0000)
now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%S.000+0000"
}

# ---------------------------------------------------------------------------
# Get current user account ID
# ---------------------------------------------------------------------------

get_my_account_id() {
    local cache="$SEEN_DIR/my_account_id"
    if [[ -f "$cache" ]]; then
        cat "$cache"
        return
    fi
    local account_id
    account_id=$(jira_api "myself" | jq -r '.accountId // empty')
    if [[ -n "$account_id" ]]; then
        echo "$account_id" > "$cache"
        echo "$account_id"
    fi
}

# ---------------------------------------------------------------------------
# JQL search helper — returns array of issues
# ---------------------------------------------------------------------------

jql_search() {
    local jql="$1"
    local fields="${2:-summary,status,updated,assignee,reporter,comment,watches}"
    local encoded_jql
    encoded_jql=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$jql" 2>/dev/null \
        || printf '%s' "$jql" | sed 's/ /%20/g; s/"/%22/g; s/=/%3D/g; s/>/%3E/g; s/</%3C/g; s/(/%28/g; s/)/%29/g')
    jira_api "search/jql?jql=${encoded_jql}&fields=${fields}&maxResults=50"
}

# ---------------------------------------------------------------------------
# Check: issues assigned to you that were recently updated
# ---------------------------------------------------------------------------

check_assigned() {
    local last_check
    last_check=$(seen_get "ts_assigned")
    local now
    now=$(now_iso)

    # On first run, set baseline and skip to avoid flooding
    if [[ -z "$last_check" ]]; then
        seen_set "ts_assigned" "$now"
        return
    fi

    local result
    result=$(jql_search "assignee = currentUser() AND updated >= \"$last_check\" ORDER BY updated DESC" "summary,status,updated,reporter")

    seen_set "ts_assigned" "$now"

    [[ -z "$result" ]] && return
    echo "$result" | jq -r '.issues[]? | "\(.key)|\(.fields.summary | .[0:80])|\(.fields.status.name)|\(.fields.reporter.displayName // "?")"' \
    | while IFS='|' read -r key summary status reporter; do
        local notif_id="assigned_${key}"
        if [[ ! -f "$NOTIF_STATE_DIR/${notif_id}.notif" ]]; then
            notif_add "$notif_id" "$key" "assigned/updated"
            send_notif "$notif_id" -u normal "Jira: $key updated" \
                "$summary\nStatus: $status  Reporter: $reporter"
        fi
    done
}

# ---------------------------------------------------------------------------
# Check: @mentions in comments (uses comment text search on currentUser)
# ---------------------------------------------------------------------------

check_mentioned() {
    local last_check
    last_check=$(seen_get "ts_mentioned")
    local now
    now=$(now_iso)

    if [[ -z "$last_check" ]]; then
        seen_set "ts_mentioned" "$now"
        return
    fi

    # JQL: issues with a comment mentioning currentUser updated since last check
    local result
    result=$(jql_search "issueFunction in commented(\"by currentUser() after \\\"$last_check\\\"\") OR (comment ~ currentUser() AND updated >= \"$last_check\")" "summary,comment") 2>/dev/null

    # Fallback simpler JQL if the above fails (issueFunction requires ScriptRunner)
    if [[ -z "$result" ]] || echo "$result" | jq -e '.errorMessages' >/dev/null 2>&1; then
        result=$(jql_search "comment ~ currentUser() AND updated >= \"$last_check\" ORDER BY updated DESC" "summary,comment")
    fi

    seen_set "ts_mentioned" "$now"

    [[ -z "$result" ]] && return

    local my_account_id
    my_account_id=$(get_my_account_id)

    echo "$result" | jq -r --arg since "$last_check" --arg me "$my_account_id" '
        .issues[]? as $issue |
        $issue.fields.comment.comments[]? |
        select(.created >= $since) |
        select(.author.accountId != $me) |
        select(.body | tostring | test("@" + $me; "i")) |
        "\($issue.key)|\(.id)|\(.author.displayName)|\(.body | tostring | split("\n")[0] | .[0:100])"
    ' | while IFS='|' read -r key comment_id author body; do
        local notif_id="mention_${key}_${comment_id}"
        if [[ ! -f "$NOTIF_STATE_DIR/${notif_id}.notif" ]]; then
            notif_add "$notif_id" "$key" "mentioned by $author"
            send_notif "$notif_id" -u normal "Jira mention: $key" \
                "$author mentioned you:\n$body"
        fi
    done
}

# ---------------------------------------------------------------------------
# Check: new comments on issues you own or reported
# ---------------------------------------------------------------------------

check_commented() {
    local last_check
    last_check=$(seen_get "ts_commented")
    local now
    now=$(now_iso)

    if [[ -z "$last_check" ]]; then
        seen_set "ts_commented" "$now"
        return
    fi

    local result
    result=$(jql_search "(assignee = currentUser() OR reporter = currentUser()) AND comment is not EMPTY AND updated >= \"$last_check\" ORDER BY updated DESC" "summary,comment")

    seen_set "ts_commented" "$now"

    [[ -z "$result" ]] && return

    local my_account_id
    my_account_id=$(get_my_account_id)

    echo "$result" | jq -r --arg since "$last_check" --arg me "$my_account_id" '
        .issues[]? as $issue |
        $issue.fields.comment.comments[]? |
        select(.created >= $since) |
        select(.author.accountId != $me) |
        "\($issue.key)|\(.id)|\(.author.displayName)|\(.body | tostring | split("\n")[0] | .[0:100])"
    ' | while IFS='|' read -r key comment_id author body; do
        local notif_id="comment_${key}_${comment_id}"
        if [[ ! -f "$NOTIF_STATE_DIR/${notif_id}.notif" ]]; then
            notif_add "$notif_id" "$key" "comment by $author"
            send_notif "$notif_id" -u normal "Jira comment: $key" \
                "$author commented:\n$body"
        fi
    done
}

# ---------------------------------------------------------------------------
# Check: status transitions on issues assigned to or reported by you
# ---------------------------------------------------------------------------

check_transitions() {
    local last_check
    last_check=$(seen_get "ts_transition")
    local now
    now=$(now_iso)

    if [[ -z "$last_check" ]]; then
        seen_set "ts_transition" "$now"
        return
    fi

    local result
    result=$(jql_search "(assignee = currentUser() OR reporter = currentUser()) AND status changed AFTER \"$last_check\" ORDER BY updated DESC" "summary,status")

    seen_set "ts_transition" "$now"

    [[ -z "$result" ]] && return

    echo "$result" | jq -r '.issues[]? | "\(.key)|\(.fields.summary | .[0:80])|\(.fields.status.name)"' \
    | while IFS='|' read -r key summary status; do
        local notif_id="transition_${key}"
        # Re-notify on each new transition (remove old notif first if present)
        # by checking if the stored status differs
        local status_file="$SEEN_DIR/status_${key}"
        local prev_status=""
        [[ -f "$status_file" ]] && prev_status=$(cat "$status_file")

        if [[ "$status" != "$prev_status" ]]; then
            # Remove stale notif for this issue (same key, new status)
            notif_remove "$notif_id" 2>/dev/null || true
            notif_add "$notif_id" "$key" "→ $status"
            send_notif "$notif_id" -u normal "Jira transition: $key" \
                "$summary\nNew status: $status"
            echo "$status" > "$status_file"
        fi
    done
}

# ---------------------------------------------------------------------------
# Check: updates on issues you watch
# ---------------------------------------------------------------------------

check_watched() {
    local last_check
    last_check=$(seen_get "ts_watched")
    local now
    now=$(now_iso)

    if [[ -z "$last_check" ]]; then
        seen_set "ts_watched" "$now"
        return
    fi

    local result
    result=$(jql_search "issue in watchedIssues() AND updated >= \"$last_check\" ORDER BY updated DESC" "summary,status,updated")

    seen_set "ts_watched" "$now"

    [[ -z "$result" ]] && return

    echo "$result" | jq -r '.issues[]? | "\(.key)|\(.fields.summary | .[0:80])|\(.fields.status.name)"' \
    | while IFS='|' read -r key summary status; do
        local notif_id="watched_${key}"
        if [[ ! -f "$NOTIF_STATE_DIR/${notif_id}.notif" ]]; then
            notif_add "$notif_id" "$key" "watched update"
            send_notif "$notif_id" -u low "Jira watched: $key" \
                "$summary\nStatus: $status"
        fi
    done
}

# ---------------------------------------------------------------------------
# Main poll cycle
# ---------------------------------------------------------------------------

poll_once() {
    local verbose="${1:-}"
    load_credentials

    local my_account_id
    my_account_id=$(get_my_account_id)
    if [[ -z "$my_account_id" ]]; then
        echo "[jira] ERROR: Could not get account ID — check credentials and API token" >&2
        echo "[jira] Debug: $(cat /tmp/jira-monitor-debug.log 2>/dev/null | tail -3)" >&2
        return 1
    fi

    [[ -n "$verbose" ]] && echo "[jira] Authenticated as $my_account_id"
    check_assigned
    check_mentioned
    check_commented
    check_transitions
    check_watched
    [[ -n "$verbose" ]] && echo "[jira] Poll complete"
}

# ---------------------------------------------------------------------------
# Daemon (single-instance via flock)
# ---------------------------------------------------------------------------

# Watch D-Bus for NotificationClosed / ActionInvoked events.
# When one fires, look up the dbus_<id> mapping file and call notif_remove.
dbus_monitor_loop() {
    dbus-monitor "interface='org.freedesktop.Notifications'" 2>/dev/null | \
    while IFS= read -r line; do
        if [[ "$line" == *"member=NotificationClosed"* || "$line" == *"member=ActionInvoked"* ]]; then
            read -r id_line
            local dbus_id
            dbus_id=$(echo "$id_line" | grep -oP 'uint32 \K[0-9]+')
            if [[ -n "$dbus_id" ]]; then
                local map_file="$NOTIF_STATE_DIR/dbus_${dbus_id}"
                if [[ -f "$map_file" ]]; then
                    local notif_id
                    notif_id=$(cat "$map_file")
                    rm -f "$map_file"
                    [[ -n "$notif_id" ]] && notif_remove "$notif_id"
                fi
            fi
        fi
    done
}

_run_monitor() {
    dbus_monitor_loop &
    while true; do
        poll_once 2>/dev/null || true
        sleep "$POLL_INTERVAL"
    done
}

start_monitor() {
    flock -n "/tmp/jira-monitor-$USER.lock" -c "$0 _run_monitor" || exit 0
}

# ---------------------------------------------------------------------------
# Mark-read: clear all tracked notifications and reset seen timestamps
# ---------------------------------------------------------------------------

mark_read() {
    notif_clear
    local now
    now=$(now_iso)
    seen_set "ts_assigned"   "$now"
    seen_set "ts_mentioned"  "$now"
    seen_set "ts_commented"  "$now"
    seen_set "ts_transition" "$now"
    seen_set "ts_watched"    "$now"
    notify-send "Jira" "All notifications marked as read"
}

# ---------------------------------------------------------------------------
# Open: open Jira dashboard (or first unread issue)
# ---------------------------------------------------------------------------

open_jira() {
    load_credentials
    local first_notif
    first_notif=$(ls "$NOTIF_STATE_DIR"/*.notif 2>/dev/null | head -1)
    if [[ -n "$first_notif" ]]; then
        local issue_key
        issue_key=$(basename "$first_notif" .notif | sed 's/^[^_]*_//' | cut -d'_' -f1)
        # Notif IDs are like assigned_KEY, comment_KEY_id, etc. — extract the Jira key
        issue_key=$(cat "$first_notif" | cut -d'|' -f1)
        xdg-open "${JIRA_URL}/browse/${issue_key}" &
    else
        xdg-open "${JIRA_URL}/jira/your-work" &
    fi
    mark_read
}

# ---------------------------------------------------------------------------
# Show: notify-send summary of unread
# ---------------------------------------------------------------------------

show_notifications() {
    notif_show_sources
}

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

case "${1:-status}" in
    monitor)        start_monitor ;;
    _run_monitor)   _run_monitor ;;
    check)          poll_once verbose ;;
    clear)          notif_clear ;;
    mark-read)      mark_read ;;
    open)           open_jira ;;
    show)           show_notifications ;;
    count)          notif_get_count ;;
    sources)        notif_show_sources ;;
    status|*)       notif_status ;;
esac
