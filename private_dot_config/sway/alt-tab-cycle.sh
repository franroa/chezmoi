#!/bin/bash
# Alt+Tab cycling with proper Alt-release detection
# This script handles the entire Alt+Tab cycle session

HISTORY_FILE="/tmp/sway-window-history"
CYCLE_POS_FILE="/tmp/sway-cycle-position"
LOCK_FILE="/tmp/sway-alt-tab.lock"

# Prevent multiple instances
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

get_focused_window() {
    swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true and .pid != null) | .id'
}

get_all_windows() {
    swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.type == "con" and .pid != null) | .id'
}

clean_history() {
    local all_windows=$(get_all_windows)
    local temp_file="${HISTORY_FILE}.tmp"
    
    > "$temp_file"
    if [ -f "$HISTORY_FILE" ]; then
        while read -r win_id; do
            if [ -n "$win_id" ] && echo "$all_windows" | grep -q "^${win_id}$"; then
                echo "$win_id" >> "$temp_file"
            fi
        done < "$HISTORY_FILE"
    fi
    
    for win_id in $all_windows; do
        if ! grep -q "^${win_id}$" "$temp_file" 2>/dev/null; then
            echo "$win_id" >> "$temp_file"
        fi
    done
    
    mv "$temp_file" "$HISTORY_FILE"
}

promote_window() {
    local win_id="$1"
    if [ -n "$win_id" ] && [ -f "$HISTORY_FILE" ]; then
        grep -v "^${win_id}$" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" 2>/dev/null || true
        echo "$win_id" | cat - "${HISTORY_FILE}.tmp" > "$HISTORY_FILE"
        rm -f "${HISTORY_FILE}.tmp"
    fi
}

focus_at_position() {
    local pos=$1
    local target=$(sed -n "$((pos + 1))p" "$HISTORY_FILE")
    if [ -n "$target" ]; then
        swaymsg "[con_id=$target]" focus >/dev/null 2>&1
    fi
}

# Check if Alt (Mod1) is currently pressed using libinput or /dev/input
is_alt_pressed() {
    # Method 1: Check via sway's input state (most reliable for Wayland)
    # We check if Mod1 modifier is active by trying to grab keyboard state
    
    # Method 2: Read from /dev/input directly
    # Alt_L is keycode 56, Alt_R is keycode 100
    # We use timeout to avoid blocking
    
    # Simplest method: use xkbcli or check /sys
    # For now, use a simple approach with libinput debug-events
    
    # Actually, the most reliable way is to subscribe to sway events
    # But for polling, we check the key file
    
    local key_state=$(cat /sys/class/leds/input3::scrolllock/brightness 2>/dev/null)
    
    # Fallback: check if we can detect key state via evtest (needs root) or similar
    # For user-space, we rely on a simpler heuristic
    
    # Use ydotool's ability or direct /dev/input reading
    # This is tricky without root access to /dev/input/*
    
    # Best approach for Wayland: monitor sway's key events
    return 1  # Assume not pressed (will use timeout as fallback)
}

# Main cycle logic
main() {
    clean_history
    
    local count=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
    if [ "$count" -lt 2 ]; then
        exit 0
    fi
    
    # Start at position 1 (previous window)
    local pos=1
    echo "$pos" > "$CYCLE_POS_FILE"
    focus_at_position "$pos"
    
    # Enter sway mode
    swaymsg mode "alt-tab"
    
    # Subscribe to sway binding events to detect Tab presses and Alt release
    swaymsg -t subscribe -m '["binding", "mode"]' | while read -r event; do
        local event_type=$(echo "$event" | jq -r 'if .change then "mode" else "binding" end')
        
        if [ "$event_type" = "mode" ]; then
            local mode=$(echo "$event" | jq -r '.current')
            if [ "$mode" = "default" ]; then
                # Mode exited - commit and stop
                current=$(get_focused_window)
                promote_window "$current"
                echo "0" > "$CYCLE_POS_FILE"
                break
            fi
        elif [ "$event_type" = "binding" ]; then
            local cmd=$(echo "$event" | jq -r '.binding.command')
            
            if [[ "$cmd" == *"next"* ]]; then
                count=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
                pos=$(cat "$CYCLE_POS_FILE" 2>/dev/null || echo "0")
                pos=$(( (pos + 1) % count ))
                echo "$pos" > "$CYCLE_POS_FILE"
                focus_at_position "$pos"
            elif [[ "$cmd" == *"prev"* ]]; then
                count=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
                pos=$(cat "$CYCLE_POS_FILE" 2>/dev/null || echo "0")
                pos=$(( (pos - 1 + count) % count ))
                echo "$pos" > "$CYCLE_POS_FILE"
                focus_at_position "$pos"
            fi
        fi
    done
}

main "$@"
