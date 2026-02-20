#!/bin/bash
# Toggle a pyprland scratchpad with exclusive behavior
# Hides all visible special workspaces before showing the requested one

SCRATCHPAD="$1"

if [[ -z "$SCRATCHPAD" ]]; then
    echo "Usage: $0 <scratchpad_name>"
    exit 1
fi

# Function to get neovim project root (LazyVim.root.git()) from active window or any running nvim
get_nvim_root() {
    local active_window
    active_window=$(hyprctl activewindow -j 2>/dev/null)
    
    local pid
    pid=$(echo "$active_window" | jq -r '.pid // empty' 2>/dev/null)
    
    local class
    class=$(echo "$active_window" | jq -r '.class // empty' 2>/dev/null)
    
    # If active window is nvim, get its project root
    if [[ "$class" == *nvim* || "$class" == *neovim* || "$class" == *Neovim* ]] && [[ -n "$pid" ]]; then
        local nvim_pid
        nvim_pid=$(pstree -p "$pid" | grep -oP 'nvim\(\K[0-9]+' | head -1)
        [[ -z "$nvim_pid" ]] && nvim_pid="$pid"
        
        local socket
        socket=$(find /run/user/$(id -u)/ -name "nvim.${nvim_pid}.*" -type s 2>/dev/null | head -1)
        
        if [[ -n "$socket" ]]; then
            local root
            root=$(nvim --server "$socket" --remote-expr 'luaeval("LazyVim.root.git()")' 2>/dev/null)
            if [[ -n "$root" && -d "$root" ]]; then
                echo "$root"
                return
            fi
        fi
    fi
    
    # Try any nvim socket
    local socket
    socket=$(find /run/user/$(id -u)/ -name 'nvim.*' -type s 2>/dev/null | head -1)
    
    if [[ -n "$socket" ]]; then
        local root
        root=$(nvim --server "$socket" --remote-expr 'luaeval("LazyVim.root.git()")' 2>/dev/null)
        if [[ -n "$root" && -d "$root" ]]; then
            echo "$root"
            return
        fi
    fi
    
    echo ""
}

# Check if this scratchpad's window is currently focused
ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class // empty' 2>/dev/null)

# Get the class for this scratchpad from pyprland config
SCRATCHPAD_CLASS=$(grep -A5 "^\[scratchpads\.$SCRATCHPAD\]" ~/.config/pypr/config.toml | grep '^class' | cut -d'"' -f2)

if [[ "$ACTIVE_CLASS" == "$SCRATCHPAD_CLASS" ]]; then
    # This scratchpad is focused - hide it
    pypr hide "$SCRATCHPAD" 2>/dev/null
else
    # For opencode_cwd, check if project root changed and kill existing window if so
    if [[ "$SCRATCHPAD" == "opencode_cwd" ]]; then
        NVIM_CWD=$(get_nvim_root)
        
        if [[ -n "$NVIM_CWD" ]]; then
            # Store CWD for the launcher script to use
            echo "$NVIM_CWD" > /tmp/opencode_cwd_target
        fi
        
        # Check if scratchpad window exists
        EXISTING_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "opencode-cwd") | .pid' 2>/dev/null)
        
        if [[ -n "$EXISTING_PID" ]]; then
            # Read the CWD we launched with (stored by launcher script)
            CURRENT_CWD=""
            if [[ -f /tmp/opencode_cwd_current ]]; then
                CURRENT_CWD=$(cat /tmp/opencode_cwd_current)
            fi
            
            # If CWD changed, kill the existing window so pyprland recreates it
            if [[ -n "$NVIM_CWD" && "$CURRENT_CWD" != "$NVIM_CWD" ]]; then
                hyprctl dispatch closewindow "class:opencode-cwd"
                sleep 0.2
            fi
        fi
    fi

    # For aoe, use the shared script to open session
    if [[ "$SCRATCHPAD" == "aoe" ]]; then
        NVIM_CWD=$(get_nvim_root)
        
        # Check for force restart flag
        if [[ -f /tmp/aoe_force_restart ]]; then
            rm -f /tmp/aoe_force_restart
        fi
        
        if [[ -n "$NVIM_CWD" ]]; then
            # Get project name and branch for title
            PROJECT_NAME=$(basename "$NVIM_CWD")
            BRANCH=$(git -C "$NVIM_CWD" branch --show-current 2>/dev/null | tr '/' '-')
            [[ -z "$BRANCH" ]] && BRANCH="main"
            SESSION_TITLE="${PROJECT_NAME}_${BRANCH}"
            
            # Use shared script to open and track session
            /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$NVIM_CWD" "$SESSION_TITLE"
        fi
        
        # We've handled everything, exit the script
        exit 0
    fi

    # Hide all VISIBLE special workspaces (check each monitor)
    # Get visible special workspace names from all monitors
    VISIBLE=$(hyprctl monitors -j | jq -r '.[].specialWorkspace.name | select(. != "" and startswith("special:S-"))' 2>/dev/null)
    
    for ws in $VISIBLE; do
        ws_name="${ws#special:}"
        hyprctl dispatch togglespecialworkspace "$ws_name"
    done
    
    # Now toggle the requested scratchpad
    pypr toggle "$SCRATCHPAD"
fi
