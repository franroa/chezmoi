#!/bin/bash
# Unified notification panel with letter shortcuts
# Press a letter to immediately trigger that notification's action

NOTIF_DIR_OPENCODE="/tmp/opencode_notifications_$USER"
NOTIF_DIR_SLACK="/tmp/slack_notifications_$USER"
LETTER_MAP_OPENCODE="/tmp/.opencode_letter_map"
LETTER_MAP_SLACK="/tmp/.slack_letter_map"

get_letter_for_notif() {
    local notif_id="$1"
    local app="$2"
    
    case "$app" in
        opencode)
            if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
                grep ":$notif_id|" "$LETTER_MAP_OPENCODE" 2>/dev/null | cut -d: -f1
            fi
            ;;
        slack)
            if [[ -f "$LETTER_MAP_SLACK" ]]; then
                grep ":$notif_id|" "$LETTER_MAP_SLACK" 2>/dev/null | cut -d: -f1
            fi
            ;;
    esac
}

build_notification_list() {
    local notifications=""
    
    # Get OpenCode notifications
    if [[ -d "$NOTIF_DIR_OPENCODE" ]]; then
        for notif_file in "$NOTIF_DIR_OPENCODE"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            local notif_id=$(basename "$notif_file" .notif)
            local content=$(cat "$notif_file")
            local letter=$(get_letter_for_notif "$notif_id" "opencode")
            
            if [[ -n "$letter" ]]; then
                notifications="$notifications$letter|opencode|$notif_id|$content\n"
            fi
        done
    fi
    
    # Get Slack notifications
    if [[ -d "$NOTIF_DIR_SLACK" ]]; then
        for notif_file in "$NOTIF_DIR_SLACK"/*.notif; do
            [[ -f "$notif_file" ]] || continue
            local notif_id=$(basename "$notif_file" .notif)
            local content=$(cat "$notif_file")
            local letter=$(get_letter_for_notif "$notif_id" "slack")
            
            if [[ -n "$letter" ]]; then
                notifications="$notifications$letter|slack|$notif_id|$content\n"
            fi
        done
    fi
    
    echo -e "$notifications"
}

trigger_notification() {
    local letter="$1"
    local notifications=$(build_notification_list)
    
    while IFS='|' read -r l app notif_id content; do
        [[ "$l" != "$letter" ]] && continue
        
        case "$app" in
            opencode)
                # Extract CWD and session from content
                local cwd=$(echo "$content" | cut -d'|' -f2)
                local session=$(echo "$content" | cut -d'|' -f3)
                
                # Close notification
                gdbus call --session \
                    --dest org.freedesktop.Notifications \
                    --object-path /org/freedesktop/Notifications \
                    --method org.freedesktop.Notifications.CloseNotification \
                    "$notif_id" 2>/dev/null
                
                # Remove from tracker
                rm -f "$NOTIF_DIR_OPENCODE/${notif_id}.notif"
                
                # Release letter
                if [[ -f "$LETTER_MAP_OPENCODE" ]]; then
                    sed -i "/^${letter}:/d" "$LETTER_MAP_OPENCODE"
                fi
                
                # Open the session
                if [[ -n "$cwd" && -n "$session" ]]; then
                    /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$cwd" "$session"
                fi
                ;;
                
            slack)
                # Close notification
                gdbus call --session \
                    --dest org.freedesktop.Notifications \
                    --object-path /org/freedesktop/Notifications \
                    --method org.freedesktop.Notifications.CloseNotification \
                    "$notif_id" 2>/dev/null
                
                # Remove from tracker
                rm -f "$NOTIF_DIR_SLACK/${notif_id}.notif"
                
                # Release letter
                if [[ -f "$LETTER_MAP_SLACK" ]]; then
                    sed -i "/^${letter}:/d" "$LETTER_MAP_SLACK"
                fi
                
                # Go to Slack
                /home/froa/.config/hypr/scripts/invoke-notification.sh
                ;;
        esac
        
        return 0
    done <<< "$notifications"
    
    return 1
}

show_notification_panel() {
    local notifications=$(build_notification_list)
    
    if [[ -z "$notifications" ]]; then
        notify-send "Notifications" "No active notifications with letter shortcuts"
        return
    fi
    
    # Build rofi options
    local options=""
    while IFS='|' read -r letter app notif_id content; do
        [[ -z "$letter" ]] && continue
        
        local app_icon=""
        case "$app" in
            opencode) app_icon="🤖" ;;
            slack) app_icon="💬" ;;
        esac
        
        options="$options$letter: $app_icon $content\n"
    done <<< "$notifications"
    
    # Show rofi menu - pressing a letter selects and triggers
    local choice=$(echo -e "$options" | rofi -dmenu -i -p "Notification:" -kb-select-1 "")
    
    # Check if a selection was made (rofi returns the selected line)
    if [[ -n "$choice" ]]; then
        # Extract letter from choice
        local letter=$(echo "$choice" | cut -d: -f1)
        trigger_notification "$letter"
    fi
}

# Handle argument
case "${1:-show}" in
    show)
        show_notification_panel
        ;;
    trigger)
        trigger_notification "$2"
        ;;
    *)
        echo "Usage: $0 show|trigger <letter>"
        ;;
esac
