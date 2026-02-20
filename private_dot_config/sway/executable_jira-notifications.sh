#!/bin/bash
# Jira Cloud notifications
# Polls Jira API for new notifications and displays via dunst
#
# Setup:
# 1. Create API token at https://id.atlassian.com/manage-profile/security/api-tokens
# 2. Set environment variables in ~/.config/jira-credentials:
#    JIRA_DOMAIN=yourcompany.atlassian.net
#    JIRA_EMAIL=your.email@company.com
#    JIRA_API_TOKEN=your_api_token

set -euo pipefail

CREDS_FILE="$HOME/.config/jira-credentials"
CACHE_FILE="/tmp/.jira_last_check_$USER"
STATE_FILE="/tmp/.jira_notif_state_$USER"
PENDING_FILE="/tmp/.jira_pending_$USER"

# Load credentials
if [[ ! -f "$CREDS_FILE" ]]; then
    cat > "$CREDS_FILE" << 'EOF'
# Jira Cloud credentials
# Get API token from: https://id.atlassian.com/manage-profile/security/api-tokens
JIRA_DOMAIN=yourcompany.atlassian.net
JIRA_EMAIL=your.email@company.com
JIRA_API_TOKEN=your_api_token
EOF
    chmod 600 "$CREDS_FILE"
    notify-send -u critical "Jira" "Please configure credentials in:\n$CREDS_FILE"
    exit 1
fi

# Source with bash explicitly (file uses bash syntax)
eval "$(grep -v '^#' "$CREDS_FILE" | grep '=')"

if [[ "$JIRA_DOMAIN" == "yourcompany.atlassian.net" ]]; then
    notify-send -u normal "Jira" "Please configure your Jira credentials in:\n$CREDS_FILE"
    exit 1
fi

AUTH=$(printf '%s' "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64 | tr -d '\n')
API_URL="https://$JIRA_DOMAIN/rest/api/3"

notify() {
    local urgency="${1:-normal}"
    local title="$2"
    local body="$3"
    touch "$PENDING_FILE"
    notify-send -u "$urgency" -i dialog-information "$title" "$body"
}

clear_pending() {
    rm -f "$PENDING_FILE"
}

has_pending() {
    [[ -f "$PENDING_FILE" ]]
}

jira_api() {
    local endpoint="$1"
    curl -s --connect-timeout 5 --max-time 10 \
         -H "Authorization: Basic $AUTH" \
         -H "Content-Type: application/json" \
         "$API_URL/$endpoint" 2>/dev/null
}

jira_search() {
    local jql="$1"
    local fields="${2:-key,summary,status,updated}"
    local max_results="${3:-10}"
    local fields_json
    fields_json=$(echo "$fields" | tr ',' '\n' | jq -R . | jq -s .)
    curl -s --connect-timeout 5 --max-time 15 \
         -X POST -H "Authorization: Basic $AUTH" \
         -H "Content-Type: application/json" \
         -d "$(jq -n --arg jql "$jql" --argjson fields "$fields_json" --argjson max "$max_results" '{jql: $jql, maxResults: $max, fields: $fields}')" \
         "$API_URL/search/jql" 2>/dev/null
}

get_my_issues() {
    local jql="assignee=currentUser() AND updated >= -1h ORDER BY updated DESC"
    jira_search "$jql" "key,summary,status,updated" 10
}

get_all_assigned_issues() {
    local jql="assignee=currentUser() AND statusCategory != Done ORDER BY updated DESC"
    jira_search "$jql" "key,summary,status" 50
}

get_recent_activity() {
    # Get issues where I was mentioned or commented on recently (last 30 min)
    local jql="(assignee = currentUser() OR watcher = currentUser() OR comment ~ currentUser()) AND updated >= -30m ORDER BY updated DESC"
    jira_search "$jql" "key,summary,updated" 20
}

get_notification_count() {
    # Check for recent activity on issues I'm involved with
    local seen_file="$STATE_FILE.activity"
    touch "$seen_file"
    
    local response
    response=$(get_recent_activity 2>/dev/null)
    
    if [[ -z "$response" ]] || echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        echo 0
        return
    fi
    
    local count=0
    while IFS='|' read -r key updated; do
        if [[ -n "$key" ]] && ! grep -qF "${key}|${updated}" "$seen_file" 2>/dev/null; then
            ((count++))
        fi
    done < <(echo "$response" | jq -r '.issues[]? | "\(.key)|\(.fields.updated)"')
    
    echo "$count"
}

mark_activity_seen() {
    local seen_file="$STATE_FILE.activity"
    local response
    response=$(get_recent_activity 2>/dev/null)
    
    if [[ -n "$response" ]] && ! echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        echo "$response" | jq -r '.issues[]? | "\(.key)|\(.fields.updated)"' >> "$seen_file"
        sort -u "$seen_file" -o "$seen_file"
        tail -200 "$seen_file" > "$seen_file.tmp" && mv "$seen_file.tmp" "$seen_file"
    fi
}

check_assigned_issues() {
    local response
    response=$(get_all_assigned_issues)
    
    if [[ -z "$response" ]] || echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        return 1
    fi
    
    # Track issue state: key|status|updated
    local seen_file="$STATE_FILE.assigned"
    local state_file="$STATE_FILE.state"
    touch "$seen_file" "$state_file"
    
    # On first run, just populate state without notifications
    if [[ ! -s "$state_file" ]]; then
        echo "$response" | jq -r '.issues[]? | "\(.key)|\(.fields.status.name)|\(.fields.updated)"' > "$state_file"
        echo "$response" | jq -r '.issues[]?.key' > "$seen_file"
        return 0
    fi
    
    echo "$response" | jq -r '.issues[]? | "\(.key)|\(.fields.summary)|\(.fields.status.name)|\(.fields.updated)"' | while IFS='|' read -r key summary status updated; do
        local old_state
        old_state=$(grep "^${key}|" "$state_file" 2>/dev/null || echo "")
        
        if [[ -z "$old_state" ]]; then
            # New issue assigned to me
            notify "normal" "Jira: New Assignment" "$key: $summary\nStatus: $status"
        else
            local old_status old_updated
            old_status=$(echo "$old_state" | cut -d'|' -f2)
            old_updated=$(echo "$old_state" | cut -d'|' -f3)
            
            if [[ "$status" != "$old_status" ]]; then
                # Status changed
                notify "normal" "Jira: Status Changed" "$key: $summary\n$old_status → $status"
            fi
        fi
    done
    
    # Update state file
    echo "$response" | jq -r '.issues[]? | "\(.key)|\(.fields.status.name)|\(.fields.updated)"' > "$state_file"
    echo "$response" | jq -r '.issues[]?.key' > "$seen_file"
}

check_mentions() {
    # Search for issues where current user was mentioned in comments recently
    local jql="comment ~ currentUser() AND updated >= -1h ORDER BY updated DESC"
    local response
    response=$(jira_search "$jql" "key,summary" 5)
    
    if [[ -z "$response" ]] || echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        return 1
    fi
    
    local seen_file="$STATE_FILE.mentions"
    touch "$seen_file"
    local timestamp=$(date +%s)
    
    echo "$response" | jq -r '.issues[]? | "\(.key)|\(.fields.summary)"' | while IFS='|' read -r key summary; do
        local cache_key="${key}_${timestamp:0:6}"  # Hourly cache
        if ! grep -qF "$cache_key" "$seen_file" 2>/dev/null; then
            notify "normal" "Jira: Mentioned in $key" "$summary"
            echo "$cache_key" >> "$seen_file"
        fi
    done
    
    tail -50 "$seen_file" > "$seen_file.tmp" 2>/dev/null && mv "$seen_file.tmp" "$seen_file"
}

get_unseen_count() {
    local seen_file="$STATE_FILE.assigned"
    local response
    response=$(get_all_assigned_issues 2>/dev/null)
    
    if [[ -z "$response" ]] || echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        echo 0
        return
    fi
    
    local unseen=0
    while IFS= read -r key; do
        if [[ -n "$key" ]] && ! grep -qF "$key" "$seen_file" 2>/dev/null; then
            ((unseen++))
        fi
    done < <(echo "$response" | jq -r '.issues[]?.key')
    echo "$unseen"
}

waybar_output() {
    local response
    local retries=3
    
    for ((i=1; i<=retries; i++)); do
        response=$(get_all_assigned_issues 2>/dev/null) || true
        if [[ -n "$response" ]] && ! echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
            break
        fi
        [[ $i -lt $retries ]] && sleep 2
    done
    
    # Fallback if API fails
    if [[ -z "$response" ]] || echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        echo '{"text":"󰌃","tooltip":"Jira: Connection error","class":"error"}'
        return
    fi
    
    local count=0
    local tooltip_issues=""
    local css_class="no-issues"
    
    count=$(echo "$response" | jq -r '.issues | length' 2>/dev/null) || count=0
    tooltip_issues=$(echo "$response" | jq -r '.issues[]? | "• \(.key): \(.fields.summary | .[0:50] | gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;"))\(.fields.status.name | " [\(.)]")"' 2>/dev/null) || tooltip_issues=""
    
    if [[ "$count" -gt 0 ]]; then
        local notif_count
        notif_count=$(get_notification_count)
        
        local nuevo_count
        nuevo_count=$(echo "$response" | jq -r '[.issues[]? | select(.fields.status.name == "Nuevo")] | length')
        
        if [[ "$notif_count" -gt 0 ]]; then
            css_class="has-unseen"
        elif [[ "$nuevo_count" -gt 0 ]]; then
            css_class="has-nuevo"
        else
            css_class="has-issues"
        fi
        
        local header
        if [[ "$notif_count" -gt 0 ]]; then
            header="Jira: $count assigned ($notif_count notifications)"
        else
            header="Jira: $count assigned"
        fi
        
        local tooltip_text
        tooltip_text="$header"$'\n'"$tooltip_issues"
        
        jq -nc --arg text "󰌃 $count" --arg tooltip "$tooltip_text" --arg class "$css_class" \
            '{text: $text, tooltip: $tooltip, class: $class}'
    else
        echo '{"text": "󰌃", "tooltip": "No issues assigned", "class": "no-issues"}'
    fi
}

mark_all_seen() {
    local response
    response=$(get_all_assigned_issues 2>/dev/null)
    local seen_file="$STATE_FILE.assigned"
    local state_file="$STATE_FILE.state"
    
    if [[ -n "$response" ]] && ! echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        echo "$response" | jq -r '.issues[]?.key' > "$seen_file"
        echo "$response" | jq -r '.issues[]? | "\(.key)|\(.fields.status.name)|\(.fields.updated)"' > "$state_file"
    fi
}

open_jira() {
    mark_all_seen
    mark_activity_seen
    clear_pending
    local jql="assignee=currentUser() AND statusCategory != Done ORDER BY updated DESC"
    local encoded_jql
    encoded_jql=$(echo "$jql" | jq -sRr @uri)
    xdg-open "https://$JIRA_DOMAIN/issues/?jql=$encoded_jql" &
}

show_tickets() {
    local response
    response=$(get_all_assigned_issues 2>/dev/null)
    
    if [[ -z "$response" ]] || echo "$response" | jq -e '.errorMessages' >/dev/null 2>&1; then
        notify-send -u normal "Jira" "Failed to fetch tickets"
        return 1
    fi
    
    local selected
    selected=$(echo "$response" | jq -r '.issues[]? | "\(.key)\t\(.fields.status.name)\t\(.fields.summary)"' | \
        wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Jira Tickets" --width 1200 --height 600 --cache-file /dev/null)
    
    if [[ -n "$selected" ]]; then
        local key
        key=$(echo "$selected" | cut -f1)
        mark_all_seen
        mark_activity_seen
        clear_pending
        xdg-open "https://$JIRA_DOMAIN/browse/$key" &
    else
        mark_activity_seen
        clear_pending
    fi
}

daemon() {
    echo "Starting Jira notification daemon..."
    while true; do
        check_assigned_issues
        check_mentions
        sleep 300  # Check every 5 minutes
    done
}

case "${1:-}" in
    check)
        check_assigned_issues
        check_mentions
        ;;
    waybar)
        waybar_output
        ;;
    open)
        open_jira
        ;;
    show)
        show_tickets
        ;;
    daemon)
        daemon
        ;;
    setup)
        echo "Edit credentials file: $CREDS_FILE"
        ${EDITOR:-nano} "$CREDS_FILE"
        ;;
    debug)
        echo "Notification count: $(get_notification_count)"
        echo "Nuevo tickets: $(get_all_assigned_issues | jq -r '[.issues[]? | select(.fields.status.name == "Nuevo")] | length')"
        echo "Assigned tickets: $(get_all_assigned_issues | jq -r '.issues | length')"
        echo "--- Raw notification API response ---"
        curl -s -H "Authorization: Basic $AUTH" "https://$JIRA_DOMAIN/rest/notifications/1.0/notifications?maxResults=5" 2>/dev/null | head -50
        ;;
    reset)
        rm -f "$STATE_FILE"* "$CACHE_FILE" "$PENDING_FILE"
        echo "State cleared. Next check will populate baseline without notifications."
        ;;
    *)
        echo "Usage: $0 [check|waybar|open|show|daemon|setup|debug|reset]"
        echo ""
        echo "Commands:"
        echo "  check  - Check for notifications now"
        echo "  waybar - Output for waybar module"
        echo "  open   - Open Jira in browser"
        echo "  show   - Show tickets via notification"
        echo "  daemon - Run as background daemon"
        echo "  setup  - Edit credentials file"
        echo "  debug  - Show notification counts"
        echo "  reset  - Clear state (stop all notifications until next change)"
        ;;
esac
