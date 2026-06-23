#!/bin/bash
# GitLab notification monitor for HyprPanel
# Polls GitLab API for:
#   - New comments on MRs authored/assigned to you
#   - MR approvals
#   - Pipeline failures on your MRs
#   - @mentions in issues and MRs
#
# Setup:
#   ~/.config/gitlab-credentials:
#     GITLAB_URL=https://gitlab.com
#     GITLAB_TOKEN=your_token

NOTIF_STATE_DIR="/tmp/gitlab_notifications_$USER"
NOTIF_COUNTER_FILE="/tmp/.gitlab_unread_$USER"
NOTIF_APP_NAME="GitLab"
CREDS_FILE="$HOME/.config/gitlab-credentials"
SEEN_DIR="/tmp/.gitlab_seen_$USER"
POLL_INTERVAL=300
FAST_RETRY_INTERVAL=20   # while waiting for the token to appear (local check only)

source /home/froa/.config/hypr/scripts/notification-tracker-lib.sh

mkdir -p "$SEEN_DIR"

# ---------------------------------------------------------------------------
# Send a desktop notification and record the dbus ID → internal notif ID map
# Usage: send_notif <notif_id> -u <urgency> <summary> <body>
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
# Send a notification carrying "Chrome" and/or "TUI" action buttons.
# Usage: send_notif_action <notif_id> <urgency_byte> <summary> <body> <url> [mr_url]
#
#   <url>     : if set, adds a "Chrome" button -> google-chrome-stable <url>
#               (may carry a #note_<id> anchor so Chrome lands on the comment)
#   [mr_url]  : if set, adds a "TUI" button    -> ghostty running `tuicr pr <mr_url>`
#               Must be the clean MR web_url (no #fragment); tuicr needs a full
#               forge URL when run outside a checkout.
#
# Uses a non-blocking `gdbus Notify` (NOT `notify-send --action`, which blocks
# forever waiting for an ActionInvoked that never comes here). Each action key is
# prefixed `scriptAction:-`; the patched hyprpanel bundle runs that command and
# dismisses the notification, deliberately avoiding the libastal-notifd invoke()
# path that SIGSEGVs the panel. Commands are shell-parsed by Astal execAsync, so
# keep them space-separated and quote-free.
# ---------------------------------------------------------------------------

send_notif_action() {
    local notif_id="$1" urgency="$2" summary="$3" body="$4" url="$5" mr_url="${6:-}"
    local -a acts=()
    if [[ -n "$url" ]]; then
        acts+=("'scriptAction:-google-chrome-stable ${url}'" "'Chrome'")
    fi
    if [[ -n "$mr_url" ]]; then
        acts+=("'scriptAction:-ghostty -e /home/froa/.config/hypr/scripts/tuicr-review.sh ${mr_url}'" "'TUI'")
    fi
    local actions="@as []"
    if [[ ${#acts[@]} -gt 0 ]]; then
        local IFS=,
        actions="[${acts[*]}]"
    fi
    local dbus_id
    dbus_id=$(gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        "GitLab" 0 "" "$summary" "$body" \
        "$actions" "{'urgency': <byte ${urgency}>}" 'int32 -1' 2>/dev/null \
        | grep -oE '[0-9]+' | head -n1)
    if [[ -n "$dbus_id" && "$dbus_id" =~ ^[0-9]+$ ]]; then
        echo "$notif_id" > "$NOTIF_STATE_DIR/dbus_${dbus_id}"
    fi
}

# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------

# Read a token from the 1Password secrets cache that fish writes at login
# ($XDG_RUNTIME_DIR/op-secrets.cache.fish, lines like `set -gx GITLAB_TOKEN x`).
# This daemon is launched by Hyprland's exec-once under /bin/sh, which never
# sources fish, so the env var is otherwise unavailable here.
read_token_from_op_cache() {
    local cache="${XDG_RUNTIME_DIR:-/tmp/op-$(id -u)}/op-secrets.cache.fish"
    [[ -r "$cache" ]] || return 1
    local tok
    tok="$(awk '$1=="set" && $3=="GITLAB_TOKEN" {print $4; exit}' "$cache")"
    # fish `set` lines quote the value; strip surrounding single/double quotes.
    tok="${tok#[\"\']}"; tok="${tok%[\"\']}"
    [[ -n "$tok" ]] && printf '%s' "$tok"
}

# Resolve the GitLab token from (in order) the environment, the 1Password cache,
# then the credentials file. Echoes the token, empty if none. Purely local: no
# API calls and no side effects, so it is safe to call cheaply on every loop
# tick to detect when the secret becomes available.
resolve_token() {
    local tok="${GITLAB_TOKEN:-}"
    if [[ -n "$tok" && "$tok" != "your_token" ]]; then
        printf '%s' "$tok"; return 0
    fi
    tok="$(read_token_from_op_cache)"
    if [[ -n "$tok" ]]; then printf '%s' "$tok"; return 0; fi
    if [[ -f "$CREDS_FILE" ]]; then
        tok="$(grep -v '^#' "$CREDS_FILE" | sed -n 's/^[[:space:]]*GITLAB_TOKEN=//p' | tail -n1)"
        tok="${tok%\"}"; tok="${tok#\"}"
        if [[ -n "$tok" && "$tok" != "your_token" ]]; then printf '%s' "$tok"; return 0; fi
    fi
    return 1
}

load_credentials() {
    # Token precedence (env > 1Password cache > credentials file) is handled by
    # resolve_token; the credentials file additionally supplies GITLAB_URL.
    local env_url="${GITLAB_URL:-}"
    local tok
    tok="$(resolve_token)"

    if [[ -f "$CREDS_FILE" ]]; then
        eval "$(grep -v '^#' "$CREDS_FILE" | grep '=')"
    fi

    [[ -n "$tok"     ]] && GITLAB_TOKEN="$tok"
    [[ -n "$env_url" ]] && GITLAB_URL="$env_url"
    GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"

    if [[ -z "${GITLAB_TOKEN:-}" || "${GITLAB_TOKEN:-}" == "your_token" ]]; then
        notify-send -u normal "GitLab" "Set \$GITLAB_TOKEN env var or configure:\n$CREDS_FILE"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# API helper
# ---------------------------------------------------------------------------

gitlab_api() {
    local endpoint="$1"
    curl -s --connect-timeout 5 --max-time 15 \
         -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
         "${GITLAB_URL}/api/v4/$endpoint" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Seen-state helpers (track last-seen IDs per category)
# ---------------------------------------------------------------------------

seen_get() {
    local key="$1"
    local file="$SEEN_DIR/${key}"
    [[ -f "$file" ]] && cat "$file" || echo "0"
}

seen_set() {
    local key="$1"
    local value="$2"
    echo "$value" > "$SEEN_DIR/${key}"
}

# ---------------------------------------------------------------------------
# Get current user
# ---------------------------------------------------------------------------

get_my_username() {
    local cache="$SEEN_DIR/my_username"
    if [[ -f "$cache" ]]; then
        cat "$cache"
        return
    fi
    local username
    username=$(gitlab_api "user" | jq -r '.username // empty')
    if [[ -n "$username" ]]; then
        echo "$username" > "$cache"
        echo "$username"
    fi
}

# ---------------------------------------------------------------------------
# Get my open MRs (assigned + authored, deduplicated)
# ---------------------------------------------------------------------------

get_my_mrs() {
    local assigned authored
    assigned=$(gitlab_api "merge_requests?state=opened&scope=assigned_to_me&per_page=50")
    authored=$(gitlab_api "merge_requests?state=opened&scope=created_by_me&per_page=50")
    echo "$assigned $authored" | jq -s 'add | unique_by(.id)' 2>/dev/null
}

# ---------------------------------------------------------------------------
# Check for new MR comments
# ---------------------------------------------------------------------------

check_mr_comments() {
    local mrs="$1"
    local my_username="$2"

    echo "$mrs" | jq -c '.[]' | while IFS= read -r mr_line; do
        local mr_id project_id mr_iid mr_title mr_web_url
        mr_id=$(echo "$mr_line" | jq -r '.id')
        project_id=$(echo "$mr_line" | jq -r '.project_id')
        mr_iid=$(echo "$mr_line" | jq -r '.iid')
        mr_title=$(echo "$mr_line" | jq -r '.title')
        mr_web_url=$(echo "$mr_line" | jq -r '.web_url // ""')

        local discussions
        discussions=$(gitlab_api "projects/$project_id/merge_requests/$mr_iid/discussions?per_page=100")
        [[ -z "$discussions" ]] && continue

        local last_seen
        last_seen=$(seen_get "mr_comments_${mr_id}")

        echo "$discussions" | jq -r --arg last_seen "$last_seen" \
            --arg my_user "$my_username" '
            .[] | .notes[]? |
            select(.id > ($last_seen | tonumber)) |
            select(.author.username != $my_user) |
            select(.author.username != "gitlab-duo" and
                   .author.username != "gitlab-duo-bot" and
                   .author.name != "GitLab Duo" and
                   (.author.username | test("duo"; "i") | not)) |
            select(.system != true) |
            "\(.id)|\(.author.name)|\(.body | split("\n")[0] | .[0:100])"
        ' | while IFS='|' read -r note_id author body; do
            local notif_id="comment_${note_id}"
            if [[ ! -f "$NOTIF_STATE_DIR/${notif_id}.notif" ]]; then
                local comment_url="$mr_web_url"
                [[ -n "$mr_web_url" ]] && comment_url="${mr_web_url}#note_${note_id}"
                notif_add "$notif_id" "!$mr_iid" "$author"
                send_notif_action "$notif_id" 1 "GitLab comment: !$mr_iid" \
                    "$author:"$'\n'"$body"$'\n\n'"$mr_title" \
                    "$comment_url" "$mr_web_url"
            fi
        done

        # Update last-seen to max note id
        local max_id
        max_id=$(echo "$discussions" | jq -r '[.[] | .notes[]? | .id] | max // 0')
        [[ "$max_id" != "null" && "$max_id" != "0" ]] && \
            seen_set "mr_comments_${mr_id}" "$max_id"
    done
}

# ---------------------------------------------------------------------------
# Check for MR approvals
# ---------------------------------------------------------------------------

check_mr_approvals() {
    local mrs="$1"
    local my_username="$2"

    echo "$mrs" | jq -c '.[]' | while IFS= read -r mr_line; do
        local mr_id project_id mr_iid mr_title mr_web_url
        mr_id=$(echo "$mr_line" | jq -r '.id')
        project_id=$(echo "$mr_line" | jq -r '.project_id')
        mr_iid=$(echo "$mr_line" | jq -r '.iid')
        mr_title=$(echo "$mr_line" | jq -r '.title')
        mr_web_url=$(echo "$mr_line" | jq -r '.web_url // ""')

        local approvals
        approvals=$(gitlab_api "projects/$project_id/merge_requests/$mr_iid/approvals")
        [[ -z "$approvals" ]] && continue

        echo "$approvals" | jq -r --arg my_user "$my_username" '
            .approved_by[]? | .user |
            select(.username != $my_user) |
            "\(.id)|\(.username)|\(.name)"
        ' | while IFS='|' read -r user_id username name; do
            local notif_id="approval_${mr_id}_${user_id}"
            if [[ ! -f "$NOTIF_STATE_DIR/${notif_id}.notif" ]]; then
                notif_add "$notif_id" "!$mr_iid" "$name approved"
                send_notif_action "$notif_id" 1 "GitLab approved: !$mr_iid" \
                    "$name approved your MR"$'\n\n'"$mr_title" \
                    "$mr_web_url" "$mr_web_url"
            fi
        done
    done
}

# ---------------------------------------------------------------------------
# Check for finished pipelines on my MRs (any completion: success or failed)
#
# Dedup is per-pipeline-id via a persistent marker, NOT a moving "max id"
# watermark. The old watermark approach marked a still-running pipeline as seen
# and then missed its later completion; keying on the pipeline id + a terminal
# status avoids that race. On the very first poll we silently baseline the
# pipelines that are already finished, so startup doesn't flood with a backlog.
# Each notification carries an "Open in GitLab" button linking to the pipeline
# page (web_url). Failed -> critical urgency, passed -> normal.
# ---------------------------------------------------------------------------

check_pipeline_finished() {
    local mrs="$1"

    local baseline_flag="$SEEN_DIR/pipeline_baseline"
    local first_run=0
    [[ ! -f "$baseline_flag" ]] && first_run=1

    echo "$mrs" | jq -c '.[]' | while IFS= read -r mr_line; do
        local project_id mr_iid mr_title mr_web_url
        project_id=$(echo "$mr_line" | jq -r '.project_id')
        mr_iid=$(echo "$mr_line" | jq -r '.iid')
        mr_title=$(echo "$mr_line" | jq -r '.title')
        mr_web_url=$(echo "$mr_line" | jq -r '.web_url // ""')

        local pipelines
        pipelines=$(gitlab_api "projects/$project_id/merge_requests/$mr_iid/pipelines?per_page=5")
        [[ -z "$pipelines" ]] && continue

        echo "$pipelines" | jq -r '
            .[] |
            select(.status == "success" or .status == "failed") |
            "\(.id)|\(.status)|\(.ref)|\(.web_url // "")"
        ' | while IFS='|' read -r pipeline_id status ref web_url; do
            local marker="$SEEN_DIR/pipeline_done_${pipeline_id}"
            [[ -f "$marker" ]] && continue        # already handled this pipeline
            : > "$marker"                          # persist dedup before notifying

            # First poll: baseline existing finished pipelines silently.
            [[ "$first_run" -eq 1 ]] && continue

            local notif_id="pipeline_${pipeline_id}"
            local pretty urgency
            if [[ "$status" == "failed" ]]; then
                pretty="failed"; urgency=2
            else
                pretty="passed"; urgency=1
            fi
            notif_add "$notif_id" "!$mr_iid" "pipeline $pretty"
            send_notif_action "$notif_id" "$urgency" \
                "GitLab pipeline $pretty: !$mr_iid" \
                "Pipeline #$pipeline_id $pretty on $ref"$'\n\n'"$mr_title" \
                "$web_url" "$mr_web_url"
        done
    done

    # Establish the baseline after the first full pass over all MRs.
    [[ "$first_run" -eq 1 ]] && : > "$baseline_flag"
}

# ---------------------------------------------------------------------------
# Check for @mentions in todos (covers issues + MRs + snippets)
# ---------------------------------------------------------------------------

check_mentions() {
    local my_username="$1"

    local todos
    todos=$(gitlab_api "todos?action=mentioned&state=pending&per_page=50")
    [[ -z "$todos" ]] && return

    local last_seen
    last_seen=$(seen_get "mentions")

    local max_id=0

    echo "$todos" | jq -r --arg last_seen "$last_seen" '
        .[] |
        select(.id > ($last_seen | tonumber)) |
        "\(.id)|\(.author.name)|\(.target_type)|\(.target_url // "")|\(.body | split("\n")[0] | .[0:100])"
    ' | while IFS='|' read -r todo_id author target_type target_url body; do
        local notif_id="mention_${todo_id}"
        if [[ ! -f "$NOTIF_STATE_DIR/${notif_id}.notif" ]]; then
            local mention_mr_url=""
            if [[ "$target_url" == *"/merge_requests/"* ]]; then
                mention_mr_url="${target_url%%#*}"   # strip #note_ anchor for tuicr
            fi
            notif_add "$notif_id" "$target_type" "$author mentioned you"
            send_notif_action "$notif_id" 1 "GitLab mention in $target_type" \
                "$author mentioned you:"$'\n'"$body" \
                "$target_url" "$mention_mr_url"
        fi
        # Track max id for next run
        echo "$todo_id" >> "$SEEN_DIR/.mention_ids_$$"
    done

    # Update last-seen mention id
    if [[ -f "$SEEN_DIR/.mention_ids_$$" ]]; then
        max_id=$(sort -n "$SEEN_DIR/.mention_ids_$$" | tail -1)
        rm -f "$SEEN_DIR/.mention_ids_$$"
        [[ -n "$max_id" ]] && seen_set "mentions" "$max_id"
    else
        # Also update from raw response in case all were already seen
        max_id=$(echo "$todos" | jq -r '[.[].id] | max // 0')
        [[ "$max_id" != "null" && "$max_id" != "0" ]] && \
            seen_set "mentions" "$max_id"
    fi
}

# ---------------------------------------------------------------------------
# Main poll cycle
# ---------------------------------------------------------------------------

poll_once() {
    load_credentials

    local my_username
    my_username=$(get_my_username)
    [[ -z "$my_username" ]] && return

    local mrs
    mrs=$(get_my_mrs)
    if [[ -z "$mrs" ]] || ! echo "$mrs" | jq -e '.[0]' >/dev/null 2>&1; then
        mrs='[]'
    fi

    check_mr_comments "$mrs" "$my_username"
    check_mr_approvals "$mrs" "$my_username"
    check_pipeline_finished "$mrs"
    check_mentions "$my_username"
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
        if [[ -n "$(resolve_token)" ]]; then
            poll_once 2>/dev/null || true
            sleep "$POLL_INTERVAL"
        else
            # No token yet. After a fresh boot the 1Password cache is empty until
            # you open a terminal and unlock it, and exec-once under /bin/sh has
            # no GITLAB_TOKEN env var. Wait on the local cache file cheaply (no
            # API calls) and pick the secret up within FAST_RETRY_INTERVAL once
            # it lands -- no restart needed.
            sleep "$FAST_RETRY_INTERVAL"
        fi
    done
}

start_monitor() {
    flock -n "/tmp/gitlab-monitor-$USER.lock" -c "$0 _run_monitor" || exit 0
}

# ---------------------------------------------------------------------------
# Mark-read: clear all tracked notifications and reset seen state
# ---------------------------------------------------------------------------

mark_read() {
    load_credentials
    notif_clear

    # Also mark all current todos as seen
    local todos
    todos=$(gitlab_api "todos?action=mentioned&state=pending&per_page=50" 2>/dev/null)
    if [[ -n "$todos" ]]; then
        local max_id
        max_id=$(echo "$todos" | jq -r '[.[].id] | max // 0')
        [[ "$max_id" != "null" && "$max_id" != "0" ]] && \
            seen_set "mentions" "$max_id"
    fi

    # Clear seen per-MR state so fresh MRs start clean
    rm -f "$SEEN_DIR"/mr_comments_* "$SEEN_DIR"/pipeline_* 2>/dev/null || true
    notify-send "GitLab" "All notifications marked as read"
}

# ---------------------------------------------------------------------------
# Open: open dashboard (or first MR if any unread)
# ---------------------------------------------------------------------------

open_gitlab() {
    load_credentials
    local first_source
    first_source=$(ls "$NOTIF_STATE_DIR"/*.notif 2>/dev/null | head -1)
    if [[ -n "$first_source" ]]; then
        # Source field is the MR ref (e.g. "!123"), build URL from it
        local ref
        ref=$(cat "$first_source" | cut -d'|' -f1)
        xdg-open "${GITLAB_URL}/dashboard/merge_requests" &
    else
        xdg-open "${GITLAB_URL}/dashboard/merge_requests?assignee_username=@me" &
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
    check)          poll_once ;;
    clear)          notif_clear ;;
    mark-read)      mark_read ;;
    open)           open_gitlab ;;
    show)           show_notifications ;;
    count)          notif_get_count ;;
    sources)        notif_show_sources ;;
    status|*)       notif_status ;;
esac
