#!/bin/bash

STATE_FILE="/tmp/pomodoro_state"
WORK_DURATION=1500   # 25 minutes
BREAK_DURATION=300   # 5 minutes

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
            notify-send "Pomodoro" "Break time! 5 minutes"
        else
            save_state "running" "$(date +%s)" "$WORK_DURATION" "work"
            notify-send "Pomodoro" "Work time! 25 minutes"
        fi
        ;;
    *)
        read -r status start_time remaining mode <<< "$(get_state)"
        
        if [[ "$status" == "stopped" ]]; then
            echo '{"text": "Start", "alt": "stopped", "percentage": 0}'
            exit 0
        fi
        
        if [[ "$status" == "running" ]]; then
            elapsed=$(($(date +%s) - start_time))
            current_remaining=$((remaining - elapsed))
        else
            current_remaining=$remaining
        fi
        
        if [[ $current_remaining -le 0 && "$status" == "running" ]]; then
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
