#!/bin/bash
# Unified Secrets Manager - Bitwarden, KeePassXC, YubiKey
# Requires: bitwarden-cli, keepassxc-cli, ykman, wofi, wl-copy, wtype

set -euo pipefail

notify() {
    notify-send -t 3000 "Secrets" "$1"
}

# ═══════════════════════════════════════════════════════════════════
# BITWARDEN
# ═══════════════════════════════════════════════════════════════════
BW_SESSION_FILE="/tmp/.bw_session_$USER"
BW_CACHE_FILE="/tmp/.bw_items_$USER"

bw_get_session() {
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

bw_unlock() {
    local password
    password=$(wofi --dmenu --style ~/.config/wofi/active-theme.css --password --prompt "Bitwarden Master Password" --lines 0)
    [[ -z "$password" ]] && return 1
    
    local session
    if ! session=$(echo "$password" | bw unlock --raw 2>/dev/null); then
        notify "Failed to unlock Bitwarden"
        return 1
    fi
    
    echo "$session" > "$BW_SESSION_FILE"
    chmod 600 "$BW_SESSION_FILE"
    echo "$session"
}

bw_get_items() {
    local session="$1"
    if [[ -f "$BW_CACHE_FILE" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$BW_CACHE_FILE")))
        if [[ $age -lt 300 ]]; then
            cat "$BW_CACHE_FILE"
            return
        fi
    fi
    bw list items --session "$session" 2>/dev/null | tee "$BW_CACHE_FILE"
}

bitwarden_menu() {
    if ! command -v bw &>/dev/null; then
        notify "Bitwarden CLI not installed\nInstall: sudo pacman -S bitwarden-cli"
        return 1
    fi
    
    if ! bw login --check &>/dev/null; then
        notify "Please log in first: bw login"
        return 1
    fi
    
    local session
    if ! session=$(bw_get_session); then
        session=$(bw_unlock) || return 1
    fi
    
    local items
    items=$(bw_get_items "$session")
    
    local names
    names=$(echo "$items" | jq -r '.[] | select(.type == 1) | "󰯄 \(.name) (\(.login.username // "no user"))"' | sort)
    
    [[ -z "$names" ]] && { notify "No items found"; return 1; }
    
    local selected
    selected=$(echo "$names" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Bitwarden" --insensitive)
    [[ -z "$selected" ]] && return 0
    
    local name
    name=$(echo "$selected" | sed 's/^󰯄 //; s/ ([^)]*)$//')
    
    local item
    item=$(echo "$items" | jq -r --arg name "$name" '.[] | select(.name == $name and .type == 1)' | head -1)
    
    local password username totp
    password=$(echo "$item" | jq -r '.login.password // empty')
    username=$(echo "$item" | jq -r '.login.username // empty')
    totp=$(echo "$item" | jq -r '.login.totp // empty')
    
    local actions=""
    [[ -n "$password" ]] && actions+="󰌋 Copy Password\n"
    [[ -n "$username" ]] && actions+="󰀄 Copy Username\n"
    [[ -n "$totp" ]] && actions+="󱅞 Copy TOTP\n"
    [[ -n "$password" ]] && actions+="󰁥 Type Password\n"
    actions+="󰁥 Type Username + Tab + Password"
    
    local action
    action=$(echo -e "$actions" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Action")
    
    case "$action" in
        *"Copy Password"*) echo -n "$password" | wl-copy; notify "Password copied (30s)" ;;
        *"Copy Username"*) echo -n "$username" | wl-copy; notify "Username copied" ;;
        *"Copy TOTP"*) 
            local code=$(bw get totp "$name" --session "$session" 2>/dev/null)
            echo -n "$code" | wl-copy
            notify "TOTP copied"
            ;;
        *"Type Password"*) sleep 0.3; wtype "$password" ;;
        *"Type Username"*) sleep 0.3; wtype "$username"; wtype -k Tab; wtype "$password" ;;
    esac
    
    # Clear clipboard after 30s for passwords
    [[ "$action" == *"Password"* ]] && (sleep 30 && wl-copy --clear) &
}

# ═══════════════════════════════════════════════════════════════════
# KEEPASSXC
# ═══════════════════════════════════════════════════════════════════
KEEPASS_DB="${KEEPASS_DB:-$HOME/Passwords.kdbx}"
KEEPASS_KEYFILE="${KEEPASS_KEYFILE:-}"

keepassxc_menu() {
    if ! command -v keepassxc-cli &>/dev/null; then
        notify "KeePassXC CLI not installed\nInstall: sudo pacman -S keepassxc"
        return 1
    fi
    
    if [[ ! -f "$KEEPASS_DB" ]]; then
        local db
        db=$(find "$HOME" -name "*.kdbx" 2>/dev/null | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Select KeePassXC database")
        [[ -z "$db" ]] && return 1
        KEEPASS_DB="$db"
    fi
    
    local password
    password=$(wofi --dmenu --style ~/.config/wofi/active-theme.css --password --prompt "KeePassXC Master Password" --lines 0)
    [[ -z "$password" ]] && return 1
    
    local keyfile_arg=""
    [[ -n "$KEEPASS_KEYFILE" && -f "$KEEPASS_KEYFILE" ]] && keyfile_arg="--key-file $KEEPASS_KEYFILE"
    
    local entries
    entries=$(echo "$password" | keepassxc-cli ls -R -f $keyfile_arg "$KEEPASS_DB" 2>/dev/null | grep -v '/$' | sort)
    
    if [[ -z "$entries" ]]; then
        notify "No entries found or wrong password"
        return 1
    fi
    
    local selected
    selected=$(echo "$entries" | sed 's/^/󰯄 /' | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "KeePassXC" --insensitive)
    [[ -z "$selected" ]] && return 0
    
    local entry
    entry=$(echo "$selected" | sed 's/^󰯄 //')
    
    local actions="󰌋 Copy Password\n󰀄 Copy Username\n󱅞 Copy TOTP\n󰁥 Type Password\n󰁥 Type Username + Tab + Password"
    local action
    action=$(echo -e "$actions" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Action")
    
    case "$action" in
        *"Copy Password"*)
            local pw
            pw=$(echo "$password" | keepassxc-cli show -s -a Password $keyfile_arg "$KEEPASS_DB" "$entry" 2>/dev/null)
            echo -n "$pw" | wl-copy
            notify "Password copied (30s)"
            (sleep 30 && wl-copy --clear) &
            ;;
        *"Copy Username"*)
            local user
            user=$(echo "$password" | keepassxc-cli show -s -a UserName $keyfile_arg "$KEEPASS_DB" "$entry" 2>/dev/null)
            echo -n "$user" | wl-copy
            notify "Username copied"
            ;;
        *"Copy TOTP"*)
            local totp
            totp=$(echo "$password" | keepassxc-cli show -t -s $keyfile_arg "$KEEPASS_DB" "$entry" 2>/dev/null | tail -1)
            echo -n "$totp" | wl-copy
            notify "TOTP copied"
            ;;
        *"Type Password"*)
            local pw
            pw=$(echo "$password" | keepassxc-cli show -s -a Password $keyfile_arg "$KEEPASS_DB" "$entry" 2>/dev/null)
            sleep 0.3
            wtype "$pw"
            ;;
        *"Type Username"*)
            local user pw
            user=$(echo "$password" | keepassxc-cli show -s -a UserName $keyfile_arg "$KEEPASS_DB" "$entry" 2>/dev/null)
            pw=$(echo "$password" | keepassxc-cli show -s -a Password $keyfile_arg "$KEEPASS_DB" "$entry" 2>/dev/null)
            sleep 0.3
            wtype "$user"
            wtype -k Tab
            wtype "$pw"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# YUBICO AUTHENTICATOR
# ═══════════════════════════════════════════════════════════════════
YUBICO_DIR="${YUBICO_DIR:-$HOME/Documents/yubico-authenticator-7.3.0-linux}"
YUBICO_APP="$YUBICO_DIR/authenticator"

yubico_menu() {
    if [[ -x "$YUBICO_APP" ]]; then
        "$YUBICO_APP" &
        notify "Yubico Authenticator launched"
    elif [[ -f "$YUBICO_APP" ]]; then
        chmod +x "$YUBICO_APP"
        "$YUBICO_APP" &
        notify "Yubico Authenticator launched"
    else
        notify "Yubico Authenticator not found at:\n$YUBICO_APP"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════════════
main_menu() {
    # Always show all three options with static icons
    local options="󰯄 Bitwarden\n󰌆 KeePassXC\n󰌋 Yubico Authenticator"
    
    local selected
    selected=$(echo -e "$options" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "Secrets Manager")
    [[ -z "$selected" ]] && exit 0
    
    case "$selected" in
        *"Bitwarden"*) bitwarden_menu ;;
        *"KeePassXC"*) keepassxc_menu ;;
        *"Yubico"*) yubico_menu ;;
    esac
}

# Allow direct access to specific manager
case "${1:-}" in
    bitwarden|bw) bitwarden_menu ;;
    keepassxc|kp) keepassxc_menu ;;
    yubico|yubi|yk) yubico_menu ;;
    *) main_menu ;;
esac
