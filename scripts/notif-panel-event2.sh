#!/bin/bash

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
PANEL_OPEN=false

socat -u UNIX-CONNECT:"$SOCKET" - | while read -r line; do
  if [[ "$line" == *"openlayer>>notificationsmenu"* ]] && [ "$PANEL_OPEN" = false ]; then
    hyprctl keyword "bind , e, exec, notify-send 'Active' 'E is now a trigger'"
    PANEL_OPEN=true
    echo "Bind Active"

  elif [[ "$line" == *"closelayer>>notificationsmenu"* ]] && [ "$PANEL_OPEN" = true ]; then
    hyprctl keyword "unbind , e"
    PANEL_OPEN=false
    echo "Bind Removed"
  fi
done
