#!/bin/bash
# Windows 11 style Alt+Tab - simple and robust version

HISTORY_FILE="/tmp/sway-window-history"
POS_FILE="/tmp/sway-cycle-pos"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() {
    echo "[$(date +%H:%M:%S)] $*" >> /tmp/sway-alt-tab.log
}

get_focused() {
    swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true and .pid != null) | .id' | head -1
}

get_all_windows() {
    swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.type == "con" and .pid != null) | .id'
}

update_history() {
    local current="$1"
    local all_windows=$(get_all_windows)
    local temp="${HISTORY_FILE}.tmp"
    
    # Start with current window at top
    echo "$current" > "$temp"
    
    # Add rest of history (excluding current)
    if [ -f "$HISTORY_FILE" ]; then
        grep -v "^${current}$" "$HISTORY_FILE" | while read -r wid; do
            echo "$all_windows" | grep -q "^${wid}$" && echo "$wid"
        done >> "$temp"
    fi
    
    # Add any new windows not in history
    for wid in $all_windows; do
        grep -q "^${wid}$" "$temp" || echo "$wid" >> "$temp"
    done
    
    mv "$temp" "$HISTORY_FILE"
}

case "$1" in
    daemon)
        log "Daemon starting"
        swaymsg -t subscribe -m '["window"]' | while read -r event; do
            change=$(echo "$event" | jq -r '.change')
            if [ "$change" = "focus" ]; then
                # Only update if not cycling
                if [ ! -f /tmp/sway-cycling ]; then
                    current=$(get_focused)
                    [ -n "$current" ] && update_history "$current"
                fi
            fi
        done
        ;;

    start)
        log "Starting cycle"
        # Mark cycling mode
        touch /tmp/sway-cycling
        
        # Ensure history exists
        [ -f "$HISTORY_FILE" ] || get_all_windows > "$HISTORY_FILE"
        
        # Start at position 1 (second window = previous)
        echo "1" > "$POS_FILE"
        
        # Focus second window in history
        target=$(sed -n '2p' "$HISTORY_FILE")
        log "Focusing position 1: $target"
        [ -n "$target" ] && swaymsg "[con_id=$target]" focus
        
        # Start alt-release watcher in background
        ( "$SCRIPT_DIR/wait-alt-release.py" && "$SCRIPT_DIR/window-switcher.sh" commit ) &
        ;;

    next)
        log "Next called"
        [ -f /tmp/sway-cycling ] || exit 0
        
        count=$(wc -l < "$HISTORY_FILE")
        [ "$count" -lt 2 ] && exit 0
        
        pos=$(cat "$POS_FILE" 2>/dev/null || echo 1)
        pos=$(( (pos + 1) % count ))
        echo "$pos" > "$POS_FILE"
        
        target=$(sed -n "$((pos + 1))p" "$HISTORY_FILE")
        log "Next: pos=$pos target=$target"
        [ -n "$target" ] && swaymsg "[con_id=$target]" focus
        ;;

    prev)
        log "Prev called"
        [ -f /tmp/sway-cycling ] || exit 0
        
        count=$(wc -l < "$HISTORY_FILE")
        [ "$count" -lt 2 ] && exit 0
        
        pos=$(cat "$POS_FILE" 2>/dev/null || echo 1)
        pos=$(( (pos - 1 + count) % count ))
        echo "$pos" > "$POS_FILE"
        
        target=$(sed -n "$((pos + 1))p" "$HISTORY_FILE")
        log "Prev: pos=$pos target=$target"
        [ -n "$target" ] && swaymsg "[con_id=$target]" focus
        ;;

    commit)
        log "Committing"
        rm -f /tmp/sway-cycling
        swaymsg mode "default"
        
        # Move current window to top of history
        current=$(get_focused)
        [ -n "$current" ] && update_history "$current"
        
        pkill -f "wait-alt-release.py" 2>/dev/null || true
        ;;

    cancel)
        log "Cancelling"
        rm -f /tmp/sway-cycling
        pkill -f "wait-alt-release.py" 2>/dev/null || true
        ;;

    *)
        echo "Usage: $0 {daemon|start|next|prev|commit|cancel}"
        ;;
esac
