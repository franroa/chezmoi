#!/bin/bash

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

echo "Script started, socket: $SOCKET" >> /tmp/notif-socket.log

socat -u UNIX-CONNECT:"$SOCKET" - 2>&1 | while read -r line; do
  echo "Received: $line" >> /tmp/notif-socket.log
  
  if [[ "$line" == *"openlayer>>notificationsmenu"* ]] || [[ "$line" == *"openlayer>>notifications-window"* ]]; then
    echo "Panel opened - binding g and 1-9" >> /tmp/notif-socket.log
    hyprctl keyword 'bind , g, exec, /home/froa/.config/hypr/scripts/notif-trigger-simple.py' >> /tmp/notif-socket.log 2>&1
    for i in 1 2 3 4 5 6 7 8 9; do
      hyprctl keyword "bind , $i, exec, /home/froa/.config/hypr/scripts/notif-trigger-simple.py $i" >> /tmp/notif-socket.log 2>&1
    done

  elif [[ "$line" == *"closelayer>>notificationsmenu"* ]] || [[ "$line" == *"closelayer>>notifications-window"* ]]; then
    echo "Panel closed - unbinding g and 1-9" >> /tmp/notif-socket.log
    hyprctl keyword "unbind , g" >> /tmp/notif-socket.log 2>&1
    for i in 1 2 3 4 5 6 7 8 9; do
      hyprctl keyword "unbind , $i" >> /tmp/notif-socket.log 2>&1
    done
  fi
done
