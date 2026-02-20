#!/bin/bash
# Scratchpad toggle script
# Usage: scratchpad.sh <name> <command> [width%] [height%] [position]
# Example: scratchpad.sh terminal "wezterm" 80 60 top

NAME="$1"
CMD="$2"
WIDTH="${3:-50}"
HEIGHT="${4:-50}"
POSITION="${5:-center}"

MARK="scratch_${NAME}"

# Check if window with mark exists
if swaymsg -t get_tree | grep -q "\"marks\":\[\"$MARK\"\]"; then
    # Window exists, check if visible
    VISIBLE=$(swaymsg -t get_tree | jq -r ".. | select(.marks? // [] | contains([\"$MARK\"])) | .visible" 2>/dev/null)
    
    if [ "$VISIBLE" = "true" ]; then
        # Hide it
        swaymsg "[con_mark=\"$MARK\"]" move scratchpad
    else
        # Show it
        swaymsg "[con_mark=\"$MARK\"]" scratchpad show
        
        # Resize and position
        swaymsg "[con_mark=\"$MARK\"]" resize set "${WIDTH} ppt" "${HEIGHT} ppt"
        
        case "$POSITION" in
            top)
                swaymsg "[con_mark=\"$MARK\"]" move position center
                swaymsg "[con_mark=\"$MARK\"]" move up 200px
                ;;
            center)
                swaymsg "[con_mark=\"$MARK\"]" move position center
                ;;
        esac
    fi
else
    # Window doesn't exist, launch it
    $CMD &
    
    # Wait for window to appear (max 3 seconds)
    for i in {1..30}; do
        sleep 0.1
        # Try to find and mark the new window based on app
        case "$NAME" in
            terminal)
                FOUND=$(swaymsg -t get_tree | jq -r '.. | select(.app_id? == "org.wezfurlong.wezterm" or .app_id? == "wezterm") | .id' 2>/dev/null | head -1)
                ;;
            notes)
                FOUND=$(swaymsg -t get_tree | jq -r '.. | select(.app_id? == "mousepad" or .app_id? == "gedit" or .app_id? == "org.gnome.TextEditor") | .id' 2>/dev/null | head -1)
                ;;
            calc)
                FOUND=$(swaymsg -t get_tree | jq -r '.. | select(.name? | test("qalc|calculator"; "i")?) | .id' 2>/dev/null | head -1)
                ;;
            music)
                FOUND=$(swaymsg -t get_tree | jq -r '.. | select(.class? == "Spotify" or .app_id? == "spotify" or .name? == "Spotify") | .id' 2>/dev/null | head -1)
                ;;
            *)
                FOUND=""
                ;;
        esac
        
        if [ -n "$FOUND" ] && [ "$FOUND" != "null" ]; then
            swaymsg "[con_id=$FOUND]" mark "$MARK"
            swaymsg "[con_mark=\"$MARK\"]" floating enable
            swaymsg "[con_mark=\"$MARK\"]" resize set "${WIDTH} ppt" "${HEIGHT} ppt"
            
            case "$POSITION" in
                top)
                    swaymsg "[con_mark=\"$MARK\"]" move position center
                    swaymsg "[con_mark=\"$MARK\"]" move up 200px
                    ;;
                center)
                    swaymsg "[con_mark=\"$MARK\"]" move position center
                    ;;
            esac
            break
        fi
    done
fi
