#!/bin/bash
# Watch notification panel and add/remove keybinds dynamically

NOTIF_KEY="bind = , e, exec, notify-send Test pressed"

add_keybind() {
    echo "Adding keybind for e..."
    hyprctl keyword "$NOTIF_KEY" 2>/dev/null
}

remove_keybind() {
    echo "Removing keybind for e..."
    hyprctl keyword "bind = , e," 2>/dev/null || true
}

check_layer() {
    hyprctl layers 2>/dev/null | grep -q "namespace: notificationsmenu"
}

was_visible=false

while true; do
    if check_layer; then
        if [ "$was_visible" = false ]; then
            echo "Panel opened - adding keybind"
            add_keybind
            was_visible=true
        fi
    else
        if [ "$was_visible" = true ]; then
            echo "Panel closed - removing keybind"
            remove_keybind
            was_visible=false
        fi
    fi
    sleep 0.2
done
