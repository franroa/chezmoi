#!/bin/bash
# SSH launcher using wofi
# Parses ~/.ssh/config and known_hosts for hosts
# Requires: wofi, wezterm (or change $TERM)

set -euo pipefail

TERM_CMD="wezterm start --"
SSH_CONFIG="$HOME/.ssh/config"
KNOWN_HOSTS="$HOME/.ssh/known_hosts"
HISTORY_FILE="$HOME/.cache/ssh_history"

mkdir -p "$(dirname "$HISTORY_FILE")"
touch "$HISTORY_FILE"

get_config_hosts() {
    if [[ -f "$SSH_CONFIG" ]]; then
        grep -i "^Host " "$SSH_CONFIG" 2>/dev/null | \
            awk '{for(i=2;i<=NF;i++) if($i !~ /[*?]/) print $i}' | \
            sort -u
    fi
}

get_known_hosts() {
    if [[ -f "$KNOWN_HOSTS" ]]; then
        cut -d' ' -f1 "$KNOWN_HOSTS" 2>/dev/null | \
            tr ',' '\n' | \
            sed 's/\[//g; s/\]:[0-9]*//g' | \
            grep -v '^|' | \
            sort -u
    fi
}

get_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        tac "$HISTORY_FILE" | awk '!seen[$0]++' | head -20
    fi
}

add_to_history() {
    local host="$1"
    echo "$host" >> "$HISTORY_FILE"
    # Keep only last 100 entries
    tail -100 "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
}

get_host_info() {
    local host="$1"
    if [[ -f "$SSH_CONFIG" ]]; then
        local user port hostname
        user=$(awk -v h="$host" '
            tolower($1) == "host" { current = 0; for(i=2;i<=NF;i++) if($i == h) current = 1 }
            current && tolower($1) == "user" { print $2; exit }
        ' "$SSH_CONFIG")
        
        hostname=$(awk -v h="$host" '
            tolower($1) == "host" { current = 0; for(i=2;i<=NF;i++) if($i == h) current = 1 }
            current && tolower($1) == "hostname" { print $2; exit }
        ' "$SSH_CONFIG")
        
        port=$(awk -v h="$host" '
            tolower($1) == "host" { current = 0; for(i=2;i<=NF;i++) if($i == h) current = 1 }
            current && tolower($1) == "port" { print $2; exit }
        ' "$SSH_CONFIG")
        
        local info=""
        [[ -n "$user" ]] && info+="$user@"
        [[ -n "$hostname" ]] && info+="$hostname" || info+="$host"
        [[ -n "$port" && "$port" != "22" ]] && info+=":$port"
        echo "$info"
    else
        echo "$host"
    fi
}

build_menu() {
    local config_hosts known_hosts history_hosts
    
    # Recent connections (with star)
    history_hosts=$(get_history)
    if [[ -n "$history_hosts" ]]; then
        echo "─── Recent ───"
        while IFS= read -r host; do
            local info
            info=$(get_host_info "$host")
            echo "󰁯 $host ($info)"
        done <<< "$history_hosts"
    fi
    
    # Config hosts
    config_hosts=$(get_config_hosts)
    if [[ -n "$config_hosts" ]]; then
        echo "─── SSH Config ───"
        while IFS= read -r host; do
            local info
            info=$(get_host_info "$host")
            echo "󰒋 $host ($info)"
        done <<< "$config_hosts"
    fi
    
    # Known hosts (excluding config hosts)
    known_hosts=$(get_known_hosts | grep -vxF -f <(echo "$config_hosts") 2>/dev/null || get_known_hosts)
    if [[ -n "$known_hosts" ]]; then
        echo "─── Known Hosts ───"
        while IFS= read -r host; do
            echo "󰟀 $host"
        done <<< "$known_hosts"
    fi
}

main() {
    local menu
    menu=$(build_menu)
    
    # Add custom option at top
    menu="󰐊 Connect to custom host...\n$menu"
    
    # Show menu
    local selected
    selected=$(echo -e "$menu" | wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "SSH" --insensitive)
    [[ -z "$selected" ]] && exit 0
    
    # Handle selection
    case "$selected" in
        "───"*)
            exit 0
            ;;
        *"custom host"*)
            local custom
            custom=$(wofi --dmenu --style ~/.config/wofi/active-theme.css --prompt "user@host:port" --lines 0)
            [[ -z "$custom" ]] && exit 0
            add_to_history "$custom"
            $TERM_CMD ssh "$custom"
            ;;
        *)
            # Extract hostname (second field)
            local host
            host=$(echo "$selected" | awk '{print $2}')
            add_to_history "$host"
            $TERM_CMD ssh "$host"
            ;;
    esac
}

main "$@"
