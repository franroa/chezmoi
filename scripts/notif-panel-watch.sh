#!/bin/bash
# Watch notification panel and bind/unbind 'g' key

check_panel() {
    hyprctl layers 2>/dev/null | grep -qE "namespace: notifications(-window|menu)"
}

panel_was_open=false

while true; do
    if check_panel; then
        if [ "$panel_was_open" = false ]; then
            echo "Panel opened - binding g"
            result=$(hyprctl keyword 'bind , g, exec, /home/froa/.config/hypr/scripts/notif-trigger-simple.py' 2>&1)
            echo "Result: $result" >> /tmp/notif-watch.log
            panel_was_open=true
        fi
    else
        if [ "$panel_was_open" = true ]; then
            echo "Panel closed - unbinding g"
            result=$(hyprctl keyword "unbind , g" 2>&1)
            echo "Result: $result" >> /tmp/notif-watch.log
            panel_was_open=false
        fi
    fi
    
    sleep 0.5
done
