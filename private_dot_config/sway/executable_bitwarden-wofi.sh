#!/bin/bash
# Bitwarden password manager integration with wofi
# Requires: bitwarden-cli (bw), jq, wl-copy, wofi

set -euo pipefail

BW_SESSION_FILE="/tmp/.bw_session_$USER"
CACHE_FILE="/tmp/.bw_items_$USER"
CACHE_TTL=300  # 5 minutes

notify() {
    notify-send -t 3000 "Bitwarden" "$1"
}

get_session() {
    if [[ -f "$BW_SESSION_FILE" ]]; then
        local session
        session=$(cat "$BW_SESSION_FILE")
        if bw unlock --check --session "$session" &>/dev/null; then
            echo "$session"
            return 0
        fi
    fi
    return 1
}

unlock_vault() {
    local password
    password=$(wofi --dmenu --style ~/.config/wofi/active-theme.css --password --prompt "Bitwarden Master Password" --lines 0)
    [[ -z "$password" ]] && exit 1
    
    local session
    if ! session=$(echo "$password" | bw unlock --raw 2>/dev/null); then
        notify "Failed to unlock vault"
        exit 1
    fi
    
    echo "$session" > "$BW_SESSION_FILE"
    chmod 600 "$BW_SESSION_FILE"
    echo "$session"
}

sync_vault() {
    local session="$1"
    bw sync --session "$session" &>/dev/null
    rm -f "$CACHE_FILE"
}

get_items() {
    local session="$1"
    
    # Use cache if fresh
    if [[ -f "$CACHE_FILE" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
        if [[ $age -lt $CACHE_TTL ]]; then
            cat "$CACHE_FILE"
            return
        fi
    fi
    
    # Fetch and cache
    bw list items --session "$session" 2>/dev/null | tee "$CACHE_FILE"
}

copy_field() {
    local value="$1"
    local field="$2"
    echo -n "$value" | wl-copy
    notify "$field copied to clipboard"
    
    # Clear clipboard after 30 seconds
    (sleep 30 && wl-copy --clear) &
}

main() {
    # Check if bw is logged in
    if ! bw login --check &>/dev/null; then
        notify "Please log in to Bitwarden first:\nbw login"
        exit 1
    fi
    
    # Get or create session
    local session
    if ! session=$(get_session); then
        session=$(unlock_vault)
    fi
    
    # Get items
    local items
    items=$(get_items "$session")
    
    # Build menu
    local names
    names=$(echo "$items" | jq -r '.[] | select(.type == 1) | "\(.name) (\(.login.username // "no username"))"' | sort)
    
    if [[ -z "$names" ]]; then
        notify "No items found"
        exit 1
    fi
    
    # Show menu
    local selected
    selected=$(echo "$names" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Bitwarden" --insensitive)
    [[ -z "$selected" ]] && exit 0
    
    # Extract name (remove username suffix)
    local name
    name=$(echo "$selected" | sed 's/ ([^)]*)$//')
    
    # Get item details
    local item
    item=$(echo "$items" | jq -r --arg name "$name" '.[] | select(.name == $name and .type == 1) | @json' | head -1)
    
    # Action menu
    local username password totp uri
    username=$(echo "$item" | jq -r '.login.username // empty')
    password=$(echo "$item" | jq -r '.login.password // empty')
    totp=$(echo "$item" | jq -r '.login.totp // empty')
    uri=$(echo "$item" | jq -r '.login.uris[0].uri // empty')
    
    local actions=""
    [[ -n "$password" ]] && actions+="󰌋 Copy Password\n"
    [[ -n "$username" ]] && actions+="󰀄 Copy Username\n"
    [[ -n "$totp" ]] && actions+="󰯄 Copy TOTP\n"
    [[ -n "$uri" ]] && actions+="󰖟 Open URL\n"
    actions+="󰁥 Type Password\n"
    actions+="󱛃 Sync Vault"
    
    local action
    action=$(echo -e "$actions" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Action")
    
    case "$action" in
        *"Copy Password"*)
            copy_field "$password" "Password"
            ;;
        *"Copy Username"*)
            copy_field "$username" "Username"
            ;;
        *"Copy TOTP"*)
            local code
            code=$(bw get totp "$name" --session "$session" 2>/dev/null)
            copy_field "$code" "TOTP"
            ;;
        *"Open URL"*)
            xdg-open "$uri" &
            ;;
        *"Type Password"*)
            sleep 0.5
            wtype "$password"
            ;;
        *"Sync Vault"*)
            sync_vault "$session"
            notify "Vault synced"
            ;;
    esac
}

main "$@"
