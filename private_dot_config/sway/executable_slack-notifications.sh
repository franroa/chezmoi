#!/bin/bash
# Slack notifications monitor for waybar
# Monitors specific channels, DMs, and mentions
#
# Setup:
# 1. Get your user token from Slack (xoxc or xoxp token)
# 2. Set in ~/.config/slack-credentials:
#    SLACK_TOKEN=xoxe.xoxp-...
#    SLACK_CHANNELS=C12345678:channel-name,C87654321:other-channel
#    (Get channel IDs: right-click channel → View channel details → ID at bottom)

set -euo pipefail

CREDS_FILE="$HOME/.config/slack-credentials"
STATE_FILE="/tmp/.slack_notif_state_$USER"
CACHE_FILE="/tmp/.slack_channel_cache_$USER"

if [[ ! -f "$CREDS_FILE" ]]; then
    cat > "$CREDS_FILE" << 'EOF'
# Slack credentials
SLACK_TOKEN=xoxe.xoxp-your-token
# Format: CHANNEL_ID:channel-name,CHANNEL_ID:channel-name
# Get channel IDs: right-click channel → View channel details → ID at bottom
SLACK_CHANNELS=C12345678:tm-platform-dev,C87654321:tm-platform
EOF
    chmod 600 "$CREDS_FILE"
    notify-send -u critical "Slack" "Please configure credentials in:\n$CREDS_FILE"
    exit 1
fi

eval "$(grep -v '^#' "$CREDS_FILE" | grep '=')"

if [[ "$SLACK_TOKEN" == *"your-token"* ]]; then
    notify-send -u normal "Slack" "Please configure your Slack token in:\n$CREDS_FILE"
    exit 1
fi

slack_api() {
    local endpoint="$1"
    shift
    curl -s --connect-timeout 5 --max-time 10 \
         -H "Authorization: Bearer $SLACK_TOKEN" \
         -H "Content-Type: application/json" \
         "https://slack.com/api/$endpoint" "$@" 2>/dev/null
}

get_my_user_id() {
    local cache_key="my_user_id"
    if [[ -f "$CACHE_FILE" ]] && grep -q "^$cache_key=" "$CACHE_FILE" 2>/dev/null; then
        grep "^$cache_key=" "$CACHE_FILE" | cut -d= -f2
        return
    fi
    
    local response
    response=$(slack_api "auth.test")
    local user_id
    user_id=$(echo "$response" | jq -r '.user_id // empty')
    
    if [[ -n "$user_id" ]]; then
        echo "$cache_key=$user_id" >> "$CACHE_FILE"
        echo "$user_id"
    fi
}

# Parse channel entry (ID:name or just ID)
parse_channel_id() {
    echo "$1" | cut -d: -f1
}

parse_channel_name() {
    local entry="$1"
    if [[ "$entry" == *":"* ]]; then
        echo "$entry" | cut -d: -f2
    else
        echo "$entry"
    fi
}

get_channel_unread() {
    local channel_entry="$1"
    local channel_id
    channel_id=$(parse_channel_id "$channel_entry")
    local channel_name
    channel_name=$(parse_channel_name "$channel_entry")
    
    if [[ -z "$channel_id" ]]; then
        echo 0
        return
    fi
    
    local last_read_file="$STATE_FILE.${channel_id}.last_read"
    local last_ts="0"
    [[ -f "$last_read_file" ]] && last_ts=$(cat "$last_read_file")
    
    local response
    response=$(slack_api "conversations.history?channel=$channel_id&limit=50")
    
    if ! echo "$response" | jq -e '.ok == true' >/dev/null 2>&1; then
        echo 0
        return
    fi
    
    local unread
    unread=$(echo "$response" | jq -r --arg ts "$last_ts" '[.messages[]? | select(.ts > $ts and .subtype == null)] | length')
    echo "${unread:-0}"
}

get_dm_unread() {
    local response
    response=$(slack_api "conversations.list?types=im&limit=100")
    
    if ! echo "$response" | jq -e '.ok == true' >/dev/null 2>&1; then
        echo 0
        return
    fi
    
    local total=0
    local last_read_file="$STATE_FILE.dms.last_read"
    local last_ts="0"
    [[ -f "$last_read_file" ]] && last_ts=$(cat "$last_read_file")
    
    local dm_channels
    dm_channels=$(echo "$response" | jq -r '.channels[]? | select(.is_im == true) | .id')
    
    for dm_id in $dm_channels; do
        local history
        history=$(slack_api "conversations.history?channel=$dm_id&limit=10")
        if echo "$history" | jq -e '.ok == true' >/dev/null 2>&1; then
            local dm_unread
            dm_unread=$(echo "$history" | jq -r --arg ts "$last_ts" '[.messages[]? | select(.ts > $ts and .subtype == null)] | length')
            ((total += dm_unread)) || true
        fi
    done
    
    echo "$total"
}

get_mentions() {
    local my_id
    my_id=$(get_my_user_id)
    
    if [[ -z "$my_id" ]]; then
        echo 0
        return
    fi
    
    local last_read_file="$STATE_FILE.mentions.last_read"
    local last_ts="0"
    [[ -f "$last_read_file" ]] && last_ts=$(cat "$last_read_file")
    
    local response
    response=$(slack_api "search.messages?query=<@$my_id>&count=20&sort=timestamp")
    
    if ! echo "$response" | jq -e '.ok == true' >/dev/null 2>&1; then
        echo 0
        return
    fi
    
    local mentions
    mentions=$(echo "$response" | jq -r --arg ts "$last_ts" '[.messages.matches[]? | select(.ts > $ts)] | length')
    echo "${mentions:-0}"
}

get_total_unread() {
    local channel_unread=0
    local dm_unread=0
    local mentions=0
    
    # Check monitored channels
    IFS=',' read -ra channels <<< "$SLACK_CHANNELS"
    for channel in "${channels[@]}"; do
        channel=$(echo "$channel" | xargs)
        local count
        count=$(get_channel_unread "$channel" 2>/dev/null) || count=0
        ((channel_unread += count)) || true
    done
    
    # Check DMs
    dm_unread=$(get_dm_unread 2>/dev/null) || dm_unread=0
    
    # Check mentions
    mentions=$(get_mentions 2>/dev/null) || mentions=0
    
    echo "$((channel_unread + dm_unread + mentions))|$channel_unread|$dm_unread|$mentions"
}

mark_channels_read() {
    IFS=',' read -ra channels <<< "$SLACK_CHANNELS"
    for channel in "${channels[@]}"; do
        channel=$(echo "$channel" | xargs)
        local channel_id
        channel_id=$(parse_channel_id "$channel")
        
        if [[ -n "$channel_id" ]]; then
            local response
            response=$(slack_api "conversations.history?channel=$channel_id&limit=1")
            local latest_ts
            latest_ts=$(echo "$response" | jq -r '.messages[0]?.ts // "0"')
            echo "$latest_ts" > "$STATE_FILE.${channel_id}.last_read"
        fi
    done
}

mark_dms_read() {
    local now
    now=$(date +%s)
    echo "$now" > "$STATE_FILE.dms.last_read"
}

mark_mentions_read() {
    local now
    now=$(date +%s)
    echo "$now" > "$STATE_FILE.mentions.last_read"
}

mark_all_read() {
    mark_channels_read
    mark_dms_read
    mark_mentions_read
}

get_channel_display_names() {
    local names=""
    IFS=',' read -ra channels <<< "$SLACK_CHANNELS"
    for channel in "${channels[@]}"; do
        channel=$(echo "$channel" | xargs)
        local name
        name=$(parse_channel_name "$channel")
        [[ -n "$names" ]] && names+=", "
        names+="$name"
    done
    echo "$names"
}

waybar_output() {
    local result
    local retries=3
    
    for ((i=1; i<=retries; i++)); do
        result=$(get_total_unread 2>/dev/null) || result=""
        if [[ -n "$result" && "$result" != "0|0|0|0" ]] || slack_api "auth.test" | jq -e '.ok == true' >/dev/null 2>&1; then
            break
        fi
        [[ $i -lt $retries ]] && sleep 2
    done
    
    result="${result:-0|0|0|0}"
    
    local total channel_unread dm_unread mentions
    total=$(echo "$result" | cut -d'|' -f1)
    channel_unread=$(echo "$result" | cut -d'|' -f2)
    dm_unread=$(echo "$result" | cut -d'|' -f3)
    mentions=$(echo "$result" | cut -d'|' -f4)
    
    local display_names
    display_names=$(get_channel_display_names)
    
    local css_class="no-messages"
    local text="󰒱"
    local tooltip="Slack: No unread\nMonitoring: $display_names"
    
    if [[ "$total" -gt 0 ]]; then
        css_class="has-unread"
        text="󰒱 $total"
        
        local details=""
        [[ "$channel_unread" -gt 0 ]] && details+="Channels: $channel_unread\n"
        [[ "$dm_unread" -gt 0 ]] && details+="DMs: $dm_unread\n"
        [[ "$mentions" -gt 0 ]] && details+="Mentions: $mentions\n"
        
        tooltip="Slack: $total unread\n${details}Monitoring: $display_names"
    fi
    
    jq -nc --arg text "$text" --arg tooltip "$tooltip" --arg class "$css_class" \
        '{text: $text, tooltip: $tooltip, class: $class}'
}

open_slack() {
    mark_all_read
    swaymsg '[class="Slack"] focus' 2>/dev/null || slack &
}

case "${1:-}" in
    waybar)
        waybar_output
        ;;
    open)
        open_slack
        ;;
    mark-read)
        mark_all_read
        ;;
    debug)
        echo "Channels config: $SLACK_CHANNELS"
        echo "User ID: $(get_my_user_id)"
        echo ""
        IFS=',' read -ra channels <<< "$SLACK_CHANNELS"
        for channel in "${channels[@]}"; do
            channel=$(echo "$channel" | xargs)
            cid=$(parse_channel_id "$channel")
            cname=$(parse_channel_name "$channel")
            echo "  $cname (id: $cid): $(get_channel_unread "$channel") unread"
        done
        echo ""
        echo "DMs: $(get_dm_unread) unread"
        echo "Mentions: $(get_mentions) unread"
        echo ""
        result=$(get_total_unread)
        echo "Total: $(echo "$result" | cut -d'|' -f1)"
        ;;
    *)
        echo "Usage: $0 [waybar|open|mark-read|debug]"
        echo ""
        echo "Configure channels in ~/.config/slack-credentials:"
        echo "  SLACK_CHANNELS=CHANNEL_ID:name,CHANNEL_ID:name"
        echo ""
        echo "Get channel IDs: right-click channel → View channel details → ID at bottom"
        ;;
esac
