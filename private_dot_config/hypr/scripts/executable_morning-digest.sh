#!/bin/bash
# Morning digest for HyprPanel
# Sends ONE start-of-day desktop notification combining:
#   1. GitLab merge requests MERGED in the previous working day, in the
#      group gitlab.com/technosylva/platform (recursively, all subprojects).
#   2. The most active Slack conversations (ranked by number of thread
#      replies) in the channels configured in ~/.config/slack-credentials
#      (SLACK_CHANNELS) -- i.e. the channels the user watches for notifications.
#
# Tokens:
#   GitLab  -> reused resolution: env > 1Password fish cache > creds file
#              (see gitlab-monitor.sh / memory gitlab-monitor-token). The op
#              cache only lands after the first terminal unlock each boot, so
#              this script retries for a bounded window before giving up.
#   Slack   -> ~/.config/slack-credentials  (SLACK_TOKEN=xoxe.xoxp-... ,
#              SLACK_CHANNELS=ID:name,ID:name). Same xoxp user token the
#              sway slack-notifications.sh script uses.
#
# Scheduled by the systemd user timer morning-digest.timer (weekday mornings).
# Run manually:  morning-digest.sh run        (force, ignore the once-a-day gate)
#                morning-digest.sh dry-run     (print to stdout, do not notify)

set -uo pipefail

GITLAB_GROUP="technosylva%2Fplatform"      # URL-encoded group full path
GITLAB_URL_DEFAULT="https://gitlab.com"
GITLAB_CREDS_FILE="$HOME/.config/gitlab-credentials"
SLACK_CREDS_FILE="$HOME/.config/slack-credentials"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/morning-digest"
mkdir -p "$STATE_DIR"
LAST_RUN_FILE="$STATE_DIR/last_run_date"      # YYYY-MM-DD of last successful send

MAX_MRS=12          # cap MR lines in the notification body
TOP_SLACK=5         # number of top Slack threads to show
SLACK_HISTORY=200   # messages pulled per channel to scan for active threads

# Token-wait tuning (GitLab op cache appears after biometric unlock).
TOKEN_WAIT_TRIES=20
TOKEN_WAIT_SLEEP=60

MODE="${1:-run}"   # run | dry-run | force

# ---------------------------------------------------------------------------
# GitLab token resolution (mirrors gitlab-monitor.sh resolve_token)
# ---------------------------------------------------------------------------
read_gitlab_token_from_op_cache() {
    local cache="${XDG_RUNTIME_DIR:-/tmp/op-$(id -u)}/op-secrets.cache.fish"
    [[ -r "$cache" ]] || return 1
    local tok
    tok="$(awk '$1=="set" && $3=="GITLAB_TOKEN" {print $4; exit}' "$cache")"
    tok="${tok#[\"\']}"; tok="${tok%[\"\']}"
    [[ -n "$tok" ]] && printf '%s' "$tok"
}

resolve_gitlab_token() {
    local tok="${GITLAB_TOKEN:-}"
    if [[ -n "$tok" && "$tok" != "your_token" ]]; then printf '%s' "$tok"; return 0; fi
    tok="$(read_gitlab_token_from_op_cache)"
    if [[ -n "$tok" ]]; then printf '%s' "$tok"; return 0; fi
    if [[ -f "$GITLAB_CREDS_FILE" ]]; then
        tok="$(grep -v '^#' "$GITLAB_CREDS_FILE" | sed -n 's/^[[:space:]]*GITLAB_TOKEN=//p' | tail -n1)"
        tok="${tok%\"}"; tok="${tok#\"}"
        if [[ -n "$tok" && "$tok" != "your_token" ]]; then printf '%s' "$tok"; return 0; fi
    fi
    return 1
}

gitlab_api() {
    local endpoint="$1"
    curl -s --connect-timeout 5 --max-time 20 \
         -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
         "${GITLAB_URL}/api/v4/$endpoint" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Window: the previous working day, [start, end) in UTC ISO8601.
#   Tue-Fri : yesterday 00:00 local -> today 00:00 local
#   Mon     : last Friday 00:00 local -> today 00:00 local (includes weekend)
# ---------------------------------------------------------------------------
compute_window() {
    local dow back
    dow="$(date +%u)"            # 1=Mon .. 7=Sun
    case "$dow" in
        1) back=3 ;;             # Monday -> back to Friday
        7) back=2 ;;             # Sunday (manual) -> Friday
        6) back=1 ;;             # Saturday (manual) -> Friday
        *) back=1 ;;             # Tue-Fri -> yesterday
    esac
    WINDOW_LABEL="$(date -d "today -${back} days" '+%A %-d %b')"
    # Local midnight boundaries converted to UTC for the API.
    WINDOW_START_UTC="$(date -u -d "$(date -d "today -${back} days" '+%Y-%m-%d') 00:00:00" '+%Y-%m-%dT%H:%M:%SZ')"
    WINDOW_END_UTC="$(date -u -d "$(date '+%Y-%m-%d') 00:00:00" '+%Y-%m-%dT%H:%M:%SZ')"
    # Slack uses epoch seconds (local boundary epochs are absolute, tz-agnostic).
    WINDOW_START_EPOCH="$(date -d "$(date -d "today -${back} days" '+%Y-%m-%d') 00:00:00" '+%s')"
    WINDOW_END_EPOCH="$(date -d "$(date '+%Y-%m-%d') 00:00:00" '+%s')"
}

# ---------------------------------------------------------------------------
# GitLab section -> sets GITLAB_BODY and GITLAB_COUNT
# ---------------------------------------------------------------------------
build_gitlab_section() {
    GITLAB_BODY=""
    GITLAB_COUNT=0

    if [[ -z "${GITLAB_TOKEN:-}" ]]; then
        GITLAB_BODY="⚠ GitLab token unavailable"
        return
    fi

    # Group-level MR list, recursive over subprojects. NOTE: merged_after/
    # merged_before are silently IGNORED at the group level, so we prefilter
    # server-side with updated_after (a safe superset: merging bumps updated_at)
    # and then filter client-side on merged_at within [start,end).
    local json page=1 raw="[]"
    while :; do
        json="$(gitlab_api "groups/${GITLAB_GROUP}/merge_requests?state=merged&updated_after=${WINDOW_START_UTC}&per_page=100&page=${page}&order_by=updated_at")"
        if ! echo "$json" | jq -e 'type=="array"' >/dev/null 2>&1; then break; fi
        local n; n="$(echo "$json" | jq 'length')"
        [[ "$n" == "0" || -z "$n" ]] && break
        raw="$(jq -s 'add' <(printf '%s' "$raw") <(printf '%s' "$json"))"
        [[ "$n" -lt 100 ]] && break
        page=$((page+1))
        [[ "$page" -gt 10 ]] && break   # safety cap
    done

    # Keep only MRs whose merge timestamp falls inside the window.
    local all
    all="$(echo "$raw" | jq -c --arg s "$WINDOW_START_UTC" --arg e "$WINDOW_END_UTC" '
        [ .[] | select(.merged_at != null and .merged_at >= $s and .merged_at < $e) ]')"

    GITLAB_COUNT="$(echo "$all" | jq 'length')"
    [[ -z "$GITLAB_COUNT" ]] && GITLAB_COUNT=0

    # Persist the merged-MR list (web_url — title (ref)) so the digest's
    # "Agent" button (mr-agent.sh digest) can summarise them.
    echo "$all" | jq -r '
        sort_by(.merged_at) | reverse | .[]
        | "\(.web_url) — \(.title) (\(.references.full // ("!"+(.iid|tostring))))"' \
        > "$STATE_DIR/last_mrs.txt" 2>/dev/null || true

    if [[ "$GITLAB_COUNT" == "0" ]]; then
        GITLAB_BODY="No MRs merged."
        return
    fi

    # Sort by merged_at; one line each:  proj!iid  title  (author)
    GITLAB_BODY="$(echo "$all" | jq -r --argjson max "$MAX_MRS" '
        sort_by(.merged_at) | reverse |
        to_entries |
        map(
          if .key < $max then
            .value as $m |
            ($m.references.full // ("!" + ($m.iid|tostring))) as $ref |
            "• \($ref) — \($m.title)  (@\($m.author.username))"
          else empty end
        ) | .[]')"

    if [[ "$GITLAB_COUNT" -gt "$MAX_MRS" ]]; then
        GITLAB_BODY="${GITLAB_BODY}
…and $((GITLAB_COUNT - MAX_MRS)) more"
    fi
}

# ---------------------------------------------------------------------------
# Slack section -> sets SLACK_BODY
# Ranks thread parents by reply_count across watched channels, where the
# thread was active within the window (parent posted OR last reply in window).
# ---------------------------------------------------------------------------
slack_api() {
    local endpoint="$1"
    curl -s --connect-timeout 5 --max-time 15 \
         -H "Authorization: Bearer $SLACK_TOKEN" \
         "https://slack.com/api/$endpoint" 2>/dev/null
}

build_slack_section() {
    SLACK_BODY=""

    if [[ ! -f "$SLACK_CREDS_FILE" ]]; then
        SLACK_BODY="⚠ No ~/.config/slack-credentials"
        return
    fi
    # shellcheck disable=SC1090
    eval "$(grep -v '^#' "$SLACK_CREDS_FILE" | grep '=')"
    if [[ -z "${SLACK_TOKEN:-}" || "$SLACK_TOKEN" == *"your-token"* ]]; then
        SLACK_BODY="⚠ Slack token not configured"
        return
    fi

    # Quick auth probe — a rotating xoxp token expires; fail soft & visibly.
    if ! slack_api "auth.test" | jq -e '.ok == true' >/dev/null 2>&1; then
        SLACK_BODY="⚠ Slack token expired — refresh SLACK_TOKEN in
  ~/.config/slack-credentials"
        return
    fi

    local rows="[]"
    IFS=',' read -ra _chans <<< "${SLACK_CHANNELS:-}"
    local entry cid cname hist
    for entry in "${_chans[@]}"; do
        entry="$(echo "$entry" | xargs)"
        [[ -z "$entry" ]] && continue
        cid="${entry%%:*}"
        cname="${entry#*:}"; [[ "$cname" == "$entry" ]] && cname="$cid"
        hist="$(slack_api "conversations.history?channel=${cid}&limit=${SLACK_HISTORY}&oldest=${WINDOW_START_EPOCH}&latest=${WINDOW_END_EPOCH}")"
        echo "$hist" | jq -e '.ok == true' >/dev/null 2>&1 || continue
        # Thread parents active in window, with replies; carry channel name.
        local chrows
        chrows="$(echo "$hist" | jq -c --arg ch "$cname" --arg start "$WINDOW_START_EPOCH" --arg end "$WINDOW_END_EPOCH" '
            [ .messages[]?
              | select(.reply_count != null and .reply_count > 0)
              | select((.ts|tonumber) < ($end|tonumber))
              | select(((.latest_reply // .ts)|tonumber) >= ($start|tonumber))
              | { ch: $ch,
                  replies: .reply_count,
                  users: (.reply_users_count // 0),
                  text: ((.text // "") | gsub("[\n\r]+";" ") | gsub("<[^>]*>";"") ),
                } ]')"
        [[ -n "$chrows" ]] && rows="$(jq -s 'add' <(printf '%s' "$rows") <(printf '%s' "$chrows"))"
    done

    local total; total="$(echo "$rows" | jq 'length')"
    if [[ -z "$total" || "$total" == "0" ]]; then
        SLACK_BODY="No active threads."
        return
    fi

    SLACK_BODY="$(echo "$rows" | jq -r --argjson top "$TOP_SLACK" '
        sort_by(.replies) | reverse | .[0:$top] | .[]
        | "• 💬\(.replies) #\(.ch): \(.text[0:80])"')"
}

# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------
send_digest() {
    local summary="$1" body="$2"
    # Buttons reuse the crash-free scriptAction:- path (memory:
    # hyprpanel-scriptaction-buttons). Quote-free, space-separated commands.
    local gl_url="${GITLAB_URL}/groups/technosylva/platform/-/merge_requests?state=merged"
    local agent_cmd="ghostty -e /home/froa/.config/hypr/scripts/mr-agent.sh digest"
    # "Open" toggles a floating foot scratchpad (like Alt+4) showing this
    # digest + today's Google Calendar agenda — see toggle-digest.sh.
    local open_cmd="/home/froa/.config/hypr/scripts/toggle-digest.sh"
    local actions="['scriptAction:-${open_cmd}', 'Open', 'scriptAction:-google-chrome-stable ${gl_url}', 'GitLab MRs', 'scriptAction:-${agent_cmd}', 'Summarize w/ agent', 'scriptAction:-xdg-open slack://open', 'Slack']"
    gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        "Morning Digest" 0 "" "$summary" "$body" \
        "$actions" "{'urgency': <byte 1>}" 'int32 0' >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    local today; today="$(date '+%Y-%m-%d')"

    # Once-a-day gate (skipped for force/dry-run). Lets the timer be generous
    # without double-sending if it fires more than once.
    if [[ "$MODE" == "run" ]]; then
        if [[ -f "$LAST_RUN_FILE" && "$(cat "$LAST_RUN_FILE")" == "$today" ]]; then
            exit 0
        fi
    fi

    # Resolve GitLab token, waiting for the op cache if needed (boot race).
    local tok=""
    local tries="$TOKEN_WAIT_TRIES"
    [[ "$MODE" == "dry-run" || "$MODE" == "force" ]] && tries=1
    while (( tries-- > 0 )); do
        tok="$(resolve_gitlab_token)" && [[ -n "$tok" ]] && break
        tok=""
        (( tries > 0 )) && sleep "$TOKEN_WAIT_SLEEP"
    done
    GITLAB_TOKEN="$tok"
    GITLAB_URL="${GITLAB_URL:-$GITLAB_URL_DEFAULT}"
    if [[ -f "$GITLAB_CREDS_FILE" ]]; then
        local _url; _url="$(grep -v '^#' "$GITLAB_CREDS_FILE" | sed -n 's/^[[:space:]]*GITLAB_URL=//p' | tail -n1)"
        [[ -n "$_url" ]] && GITLAB_URL="$_url"
    fi

    compute_window
    build_gitlab_section
    build_slack_section

    local summary="☀ Morning digest — ${WINDOW_LABEL}"
    local body="📦 Platform MRs merged (${GITLAB_COUNT}):
${GITLAB_BODY}

💬 Top Slack threads:
${SLACK_BODY}"

    # Cache the rendered digest so the "Open"/Alt+6 scratchpad (digest-window.sh)
    # can show exactly what the notification showed, alongside the calendar.
    printf '%s\n\n%s\n' "$summary" "$body" > "$STATE_DIR/last_digest.txt" 2>/dev/null || true

    if [[ "$MODE" == "dry-run" ]]; then
        printf '%s\n\n%s\n' "$summary" "$body"
        exit 0
    fi

    send_digest "$summary" "$body"
    echo "$today" > "$LAST_RUN_FILE"
}

main
