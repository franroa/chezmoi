#!/bin/bash
# Move all windows to their assigned workspaces based on config rules
# Works with Hyprland

set -uo pipefail

declare -A ASSIGNMENTS=(
    # Workspace 1 - Terminal
    ["kitty"]=1
    ["Kitty"]=1
    ["Alacritty"]=1
    ["wezterm"]=1
    ["org.wezfurlong.wezterm"]=1
    ["ghostty"]=1
    ["com.mitchellh.ghostty"]=1
    ["foot"]=1
    
    # Workspace 2 - Firefox
    ["firefox"]=2
    ["Firefox"]=2
    ["firefox-esr"]=2
    
    # Workspace 3 - Chrome
    ["google-chrome"]=3
    ["Google-chrome"]=3
    ["chromium"]=3
    ["Chromium"]=3
    
    # Workspace 4 - Slack
    ["Slack"]=4
    ["slack"]=4
    ["com.slack.Slack"]=4
    
    # Workspace 5 - Files
    ["org.gnome.Nautilus"]=5
    ["nautilus"]=5
    ["Nautilus"]=5
    ["thunar"]=5
    ["Thunar"]=5
    ["dolphin"]=5
    
    # Workspace 6 - Notion
    ["notion-snap-reborn"]=6
    ["Notion"]=6
    
    # Workspace 7 - Spotify
    ["Spotify"]=7
    ["spotify"]=7
    
    # Workspace 8 - Settings/Bitwarden
    ["Bitwarden"]=8
    ["org.gnome.Settings"]=8
    ["gnome-control-center"]=8
    
    # Workspace 9 - K8s Sandbox
    ["kubie-sandbox-terminal"]=9
    
    # Workspace 10-15 - K8s Live clusters
    ["kubie-live-terminal"]=10
)

notify() {
    notify-send -t 3000 "Organize Windows" "$1"
}

get_windows() {
    hyprctl clients -j | jq -r '.[] | "\(.address)|\(.class)|\(.workspace.id)"'
}

get_target_workspace() {
    local class="$1"
    
    if [[ -n "$class" && -n "${ASSIGNMENTS[$class]:-}" ]]; then
        echo "${ASSIGNMENTS[$class]}"
        return
    fi
    
    echo ""
}

main() {
    local moved=0
    local total=0
    
    while IFS='|' read -r address class current_ws; do
        [[ -z "$address" ]] && continue
        
        local target_ws
        target_ws=$(get_target_workspace "$class")
        
        if [[ -n "$target_ws" ]]; then
            ((total++))
            if [[ "$current_ws" != "$target_ws" ]]; then
                hyprctl dispatch movetoworkspacesilent "$target_ws,address:$address" 2>/dev/null
                ((moved++))
                echo "Moved $class from workspace $current_ws to $target_ws"
            fi
        fi
    done < <(get_windows)
    
    if [[ $moved -gt 0 ]]; then
        notify "Moved $moved window(s) to their assigned workspaces"
    else
        notify "All $total assigned windows already in place"
    fi
}

if [[ "${1:-}" == "--app" && -n "${2:-}" ]]; then
    app="$2"
    target="${ASSIGNMENTS[$app]:-}"
    if [[ -n "$target" ]]; then
        hyprctl dispatch movetoworkspacesilent "$target,class:$app" 2>/dev/null
        notify "Moved $app to workspace $target"
    else
        notify "No assignment found for $app"
    fi
    exit 0
fi

main
