#!/bin/bash
# Toggle keyd layer when notification panel opens/closes

NOTIF_NAMESPACE="notifications-window"
PANEL_WAS_OPEN=false

check_panel() {
    hyprctl layers 2>/dev/null | grep -q "namespace: ${NOTIF_NAMESPACE}"
}

while true; do
    if check_panel; then
        if [ "$PANEL_WAS_OPEN" = false ]; then
            echo "Panel opened - activating keyd notification layer"
            sudo keyd bind notification layer 2>/dev/null
            PANEL_WAS_OPEN=true
        fi
    else
        if [ "$PANEL_WAS_OPEN" = true ]; then
            echo "Panel closed - deactivating keyd notification layer"
            sudo keyd unbind notification layer 2>/dev/null || true
            PANEL_WAS_OPEN=false
        fi
    fi
    
    sleep 0.3
done
