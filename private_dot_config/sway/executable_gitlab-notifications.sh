#!/bin/bash
# GitLab MR comment notifications for waybar
# Monitors merge requests for new comments (excluding GitLab Duo)
#
# Setup:
# 1. Create a personal access token at https://gitlab.com/-/user_settings/personal_access_tokens
# 2. Required scopes: read_api
# 3. Set in ~/.config/gitlab-credentials:
#    GITLAB_URL=https://gitlab.com
#    GITLAB_TOKEN=your_token

set -euo pipefail

CREDS_FILE="$HOME/.config/gitlab-credentials"
STATE_FILE="/tmp/.gitlab_notif_state_$USER"

if [[ ! -f "$CREDS_FILE" ]]; then
    cat > "$CREDS_FILE" << 'EOF'
# GitLab credentials
# Create token at: https://gitlab.com/-/user_settings/personal_access_tokens
# Required scopes: read_api
GITLAB_URL=https://gitlab.com
GITLAB_TOKEN=your_token
EOF
    chmod 600 "$CREDS_FILE"
    notify-send -u critical "GitLab" "Please configure credentials in:\n$CREDS_FILE"
    exit 1
fi

eval "$(grep -v '^#' "$CREDS_FILE" | grep '=')"

if [[ "$GITLAB_TOKEN" == "your_token" ]]; then
    notify-send -u normal "GitLab" "Please configure your GitLab token in:\n$CREDS_FILE"
    exit 1
fi

gitlab_api() {
    local endpoint="$1"
    curl -s --connect-timeout 5 --max-time 15 \
         -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
         "${GITLAB_URL}/api/v4/$endpoint" 2>/dev/null
}

get_my_mrs() {
    # Get MRs assigned to me, authored by me, or where I participated
    local assigned authored
    assigned=$(gitlab_api "merge_requests?state=opened&scope=assigned_to_me&per_page=50")
    authored=$(gitlab_api "merge_requests?state=opened&scope=created_by_me&per_page=50")
    
    # Merge and deduplicate by id
    echo "$assigned $authored" | jq -s 'add | unique_by(.id)'
}

get_mr_discussions() {
    local project_id="$1"
    local mr_iid="$2"
    gitlab_api "projects/$project_id/merge_requests/$mr_iid/discussions?per_page=100"
}

get_last_seen_comment() {
    local mr_id="$1"
    local seen_file="$STATE_FILE.mr_$mr_id"
    if [[ -f "$seen_file" ]]; then
        cat "$seen_file"
    else
        echo "0"
    fi
}

set_last_seen_comment() {
    local mr_id="$1"
    local comment_id="$2"
    local seen_file="$STATE_FILE.mr_$mr_id"
    echo "$comment_id" > "$seen_file"
}

check_mr_comments() {
    local mrs
    mrs=$(get_my_mrs)
    
    if [[ -z "$mrs" ]] || ! echo "$mrs" | jq -e '.[0]' >/dev/null 2>&1; then
        return 1
    fi
    
    local total_new=0
    local mr_details=""
    
    while IFS= read -r mr_line; do
        local mr_id project_id mr_iid mr_title mr_web_url
        mr_id=$(echo "$mr_line" | jq -r '.id')
        project_id=$(echo "$mr_line" | jq -r '.project_id')
        mr_iid=$(echo "$mr_line" | jq -r '.iid')
        mr_title=$(echo "$mr_line" | jq -r '.title')
        mr_web_url=$(echo "$mr_line" | jq -r '.web_url')
        
        local discussions
        discussions=$(get_mr_discussions "$project_id" "$mr_iid")
        
        if [[ -z "$discussions" ]]; then
            continue
        fi
        
        local last_seen
        last_seen=$(get_last_seen_comment "$mr_id")
        
        # Get new comments excluding GitLab Duo (gitlab-duo-bot or similar)
        local new_comments
        new_comments=$(echo "$discussions" | jq -r --arg last_seen "$last_seen" '
            [.[] | .notes[]? | 
             select(.id > ($last_seen | tonumber)) |
             select(.author.username != "gitlab-duo" and 
                    .author.username != "gitlab-duo-bot" and
                    .author.name != "GitLab Duo" and
                    (.author.username | test("duo"; "i") | not)) |
             select(.system != true)
            ] | length
        ')
        
        if [[ "$new_comments" -gt 0 ]]; then
            ((total_new += new_comments)) || true
            mr_details+="• !$mr_iid: $mr_title ($new_comments new)\n"
        fi
    done < <(echo "$mrs" | jq -c '.[]')
    
    echo "$total_new|$mr_details"
}

mark_all_seen() {
    local mrs
    mrs=$(get_my_mrs 2>/dev/null)
    
    if [[ -z "$mrs" ]] || ! echo "$mrs" | jq -e '.[0]' >/dev/null 2>&1; then
        return
    fi
    
    while IFS= read -r mr_line; do
        local mr_id project_id mr_iid
        mr_id=$(echo "$mr_line" | jq -r '.id')
        project_id=$(echo "$mr_line" | jq -r '.project_id')
        mr_iid=$(echo "$mr_line" | jq -r '.iid')
        
        local discussions
        discussions=$(get_mr_discussions "$project_id" "$mr_iid" 2>/dev/null)
        
        if [[ -n "$discussions" ]]; then
            local max_comment_id
            max_comment_id=$(echo "$discussions" | jq -r '[.[] | .notes[]? | .id] | max // 0')
            if [[ "$max_comment_id" != "null" && "$max_comment_id" != "0" ]]; then
                set_last_seen_comment "$mr_id" "$max_comment_id"
            fi
        fi
    done < <(echo "$mrs" | jq -c '.[]')
}

waybar_output() {
    local result
    local retries=3
    
    for ((i=1; i<=retries; i++)); do
        result=$(check_mr_comments 2>/dev/null) || result=""
        if [[ -n "$result" ]]; then
            break
        fi
        [[ $i -lt $retries ]] && sleep 2
    done
    
    # Handle timeout/error
    if [[ -z "$result" ]]; then
        echo '{"text":"󰮠","tooltip":"GitLab: Connection error","class":"error"}'
        return
    fi
    
    local count mr_details
    count=$(echo "$result" | cut -d'|' -f1)
    mr_details=$(echo "$result" | cut -d'|' -f2-)
    
    local mrs
    mrs=$(get_my_mrs 2>/dev/null)
    local mr_count=0
    if [[ -n "$mrs" ]] && echo "$mrs" | jq -e '.[0]' >/dev/null 2>&1; then
        mr_count=$(echo "$mrs" | jq -r 'length')
    fi
    
    local css_class="no-comments"
    local text="󰮠"
    local tooltip="GitLab: No new comments\n$mr_count open MRs assigned"
    
    if [[ "$count" -gt 0 ]]; then
        css_class="has-comments"
        text="󰮠 $count"
        # Escape ampersands for waybar tooltip
        mr_details=$(echo -e "$mr_details" | sed 's/&/\&amp;/g')
        tooltip="GitLab: $count new comments\n${mr_details}$mr_count open MRs assigned"
    fi
    
    jq -nc --arg text "$text" --arg tooltip "$tooltip" --arg class "$css_class" \
        '{text: $text, tooltip: $tooltip, class: $class}'
}

send_notifications() {
    local mrs
    mrs=$(get_my_mrs)
    
    if [[ -z "$mrs" ]] || ! echo "$mrs" | jq -e '.[0]' >/dev/null 2>&1; then
        return
    fi
    
    while IFS= read -r mr_line; do
        local mr_id project_id mr_iid mr_title
        mr_id=$(echo "$mr_line" | jq -r '.id')
        project_id=$(echo "$mr_line" | jq -r '.project_id')
        mr_iid=$(echo "$mr_line" | jq -r '.iid')
        mr_title=$(echo "$mr_line" | jq -r '.title')
        
        local discussions
        discussions=$(get_mr_discussions "$project_id" "$mr_iid")
        
        if [[ -z "$discussions" ]]; then
            continue
        fi
        
        local last_seen
        last_seen=$(get_last_seen_comment "$mr_id")
        
        # Get new comments with author info
        echo "$discussions" | jq -r --arg last_seen "$last_seen" '
            .[] | .notes[]? | 
            select(.id > ($last_seen | tonumber)) |
            select(.author.username != "gitlab-duo" and 
                   .author.username != "gitlab-duo-bot" and
                   .author.name != "GitLab Duo" and
                   (.author.username | test("duo"; "i") | not)) |
            select(.system != true) |
            "\(.author.name)|\(.body | split("\n")[0] | .[0:100])"
        ' | while IFS='|' read -r author body; do
            if [[ -n "$author" ]]; then
                notify-send -u normal "GitLab: !$mr_iid" "$author:\n$body"
            fi
        done
    done < <(echo "$mrs" | jq -c '.[]')
}

open_gitlab() {
    mark_all_seen
    local mrs
    mrs=$(get_my_mrs 2>/dev/null)
    
    if [[ -n "$mrs" ]] && echo "$mrs" | jq -e '.[0]' >/dev/null 2>&1; then
        local url
        url=$(echo "$mrs" | jq -r '.[0].web_url')
        xdg-open "$url" &
    else
        xdg-open "${GITLAB_URL}/dashboard/merge_requests?assignee_username=@me" &
    fi
}

show_mrs() {
    local mrs
    mrs=$(get_my_mrs 2>/dev/null)
    
    if [[ -z "$mrs" ]] || ! echo "$mrs" | jq -e '.[0]' >/dev/null 2>&1; then
        notify-send -u normal "GitLab" "No open MRs assigned"
        return
    fi
    
    local selected
    selected=$(echo "$mrs" | jq -r '.[] | "!\(.iid)\t\(.title)"' | \
        wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "GitLab MRs" --width 1200 --height 600 --cache-file /dev/null)
    
    if [[ -n "$selected" ]]; then
        local iid
        iid=$(echo "$selected" | cut -f1 | sed 's/!//')
        local url
        url=$(echo "$mrs" | jq -r --arg iid "$iid" '.[] | select(.iid == ($iid | tonumber)) | .web_url')
        mark_all_seen
        xdg-open "$url" &
    fi
}

daemon() {
    echo "Starting GitLab notification daemon..."
    while true; do
        send_notifications
        sleep 300
    done
}

case "${1:-}" in
    waybar)
        waybar_output
        ;;
    open)
        open_gitlab
        ;;
    show)
        show_mrs
        ;;
    check)
        send_notifications
        ;;
    mark-read)
        mark_all_seen
        ;;
    daemon)
        daemon
        ;;
    debug)
        echo "Open MRs: $(get_my_mrs | jq -r 'length')"
        result=$(check_mr_comments)
        echo "New comments: $(echo "$result" | cut -d'|' -f1)"
        ;;
    *)
        echo "Usage: $0 [waybar|open|show|check|mark-read|daemon|debug]"
        ;;
esac
