#!/bin/bash

STATE_FILE="/tmp/pomodoro_state"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hyprpanel/pomodoro.conf"

# Default durations
WORK_DURATION=1500   # 25 minutes
BREAK_DURATION=300   # 5 minutes

# Load config if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

get_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "stopped 0 0 work"
    fi
}

save_state() {
    echo "$1 $2 $3 $4" > "$STATE_FILE"
}

format_time() {
    local secs=$1
    printf "%02d:%02d" $((secs / 60)) $((secs % 60))
}

case "$1" in
    toggle)
        read -r status start_time remaining mode <<< "$(get_state)"
        if [[ "$status" == "running" ]]; then
            elapsed=$(($(date +%s) - start_time))
            new_remaining=$((remaining - elapsed))
            [[ $new_remaining -lt 0 ]] && new_remaining=0
            save_state "paused" 0 "$new_remaining" "$mode"
        elif [[ "$status" == "paused" ]]; then
            save_state "running" "$(date +%s)" "$remaining" "$mode"
        else
            save_state "running" "$(date +%s)" "$WORK_DURATION" "work"
        fi
        ;;
    reset)
        save_state "stopped" 0 0 "work"
        ;;
    skip)
        read -r status start_time remaining mode <<< "$(get_state)"
        if [[ "$mode" == "work" ]]; then
            save_state "running" "$(date +%s)" "$BREAK_DURATION" "break"
            notify-send "Pomodoro" "Break time! $((BREAK_DURATION / 60)) minutes"
        else
            save_state "running" "$(date +%s)" "$WORK_DURATION" "work"
            notify-send "Pomodoro" "Work time! $((WORK_DURATION / 60)) minutes"
        fi
        ;;
    config)
        work_min=$(printf "25\n30\n45\n50\n60" | rofi -dmenu -p "󰔟 Focus (min)" -mesg "Select focus duration" -theme-str 'listview {lines: 5;}')
        [[ -z "$work_min" ]] && exit 0
        break_min=$(printf "5\n10\n15\n20" | rofi -dmenu -p "󰒫 Break (min)" -mesg "Select break duration" -theme-str 'listview {lines: 4;}')
        [[ -z "$break_min" ]] && exit 0
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "WORK_DURATION=$((work_min * 60))" > "$CONFIG_FILE"
        echo "BREAK_DURATION=$((break_min * 60))" >> "$CONFIG_FILE"
        notify-send "Pomodoro" "Set to ${work_min}min focus / ${break_min}min break"
        # Reset to apply new settings
        save_state "stopped" 0 0 "work"
        ;;
    *)
        read -r status start_time remaining mode <<< "$(get_state)"
        
        if [[ "$status" == "stopped" ]]; then
            exit 0
        fi
        
        if [[ "$status" == "running" ]]; then
            elapsed=$(($(date +%s) - start_time))
            current_remaining=$((remaining - elapsed))
        else
            current_remaining=$remaining
        fi
        
        if [[ $current_remaining -le 0 && "$status" == "running" ]]; then
            pw-play /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga &
            if [[ "$mode" == "work" ]]; then
                notify-send "Pomodoro" "Work session complete! Take a break." -u critical
                save_state "running" "$(date +%s)" "$BREAK_DURATION" "break"
                current_remaining=$BREAK_DURATION
                mode="break"
            else
                notify-send "Pomodoro" "Break over! Time to work." -u critical
                save_state "running" "$(date +%s)" "$WORK_DURATION" "work"
                current_remaining=$WORK_DURATION
                mode="work"
            fi
        fi
        
        [[ $current_remaining -lt 0 ]] && current_remaining=0
        
        if [[ "$mode" == "work" ]]; then
            total=$WORK_DURATION
        else
            total=$BREAK_DURATION
        fi
        percentage=$(( (total - current_remaining) * 100 / total ))
        
        time_str=$(format_time $current_remaining)
        
        if [[ "$status" == "paused" ]]; then
            echo "{\"text\": \"$time_str\", \"alt\": \"paused\", \"percentage\": $percentage}"
        else
            echo "{\"text\": \"$time_str\", \"alt\": \"$mode\", \"percentage\": $percentage}"
        fi
        ;;
esac
