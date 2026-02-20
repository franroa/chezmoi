#!/bin/bash
# Fix hyprpanel CSS by removing @charset that GTK4 doesn't support
CSS_FILE="/tmp/hyprpanel/main.css"

mkdir -p /tmp/hyprpanel

LAST_MOD=0
while true; do
    if [[ -f "$CSS_FILE" ]]; then
        CURRENT_MOD=$(stat -c %Y "$CSS_FILE" 2>/dev/null || echo 0)
        if [[ "$CURRENT_MOD" != "$LAST_MOD" ]]; then
            if head -1 "$CSS_FILE" 2>/dev/null | grep -q "@charset"; then
                sed -i '1{/@charset/d}' "$CSS_FILE"
            fi
            LAST_MOD=$CURRENT_MOD
        fi
    fi
    sleep 0.5
done
