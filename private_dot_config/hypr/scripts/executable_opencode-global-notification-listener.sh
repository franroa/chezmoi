#!/bin/bash
# Global notification action listener
# Monitors ALL notification actions and handles OpenCode notifications

TRACKER="/home/froa/.config/hypr/scripts/opencode-notification-tracker.sh"
OPEN_SCRIPT="/home/froa/.config/hypr/scripts/opencode-open-latest-notification.sh"

echo "Global notification action listener started"

# Monitor for ActionInvoked signals from org.freedesktop.Notifications
gdbus monitor --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications 2>/dev/null | \
while read -r line; do
  if echo "$line" | grep -q "ActionInvoked"; then
    # Extract notification ID
    NOTIF_ID=$(echo "$line" | grep -oP 'uint32 \K\d+' | head -1)
    
    if [[ -n "$NOTIF_ID" ]]; then
      echo "ActionInvoked for notification ID: $NOTIF_ID"
      
      # Check if this is an OpenCode notification
      LETTER_MAP="/tmp/.opencode_letter_map"
      if [[ -f "$LETTER_MAP" ]]; then
        # Check if any letter maps to this notifId
        LETTER=$(grep ":$NOTIF_ID|" "$LETTER_MAP" 2>/dev/null | cut -d: -f1)
        
        if [[ -n "$LETTER" ]]; then
          echo "Opening OpenCode notification: letter=$LETTER, id=$NOTIF_ID"
          
          # Get the notification info
          NOTIF_INFO=$(grep "^${LETTER}:" "$LETTER_MAP" 2>/dev/null | head -1)
          CWD=$(echo "$NOTIF_INFO" | cut -d'|' -f2)
          SESSION_NAME=$(echo "$NOTIF_INFO" | cut -d'|' -f3)
          
          # Remove from tracker
          "$TRACKER" remove "$NOTIF_ID" 2>/dev/null
          
          # Release the letter
          USED=$(cat /tmp/.opencode_letters 2>/dev/null | tr ',' '\n' | grep -v "^$LETTER$" | tr '\n' ',' | sed 's/,$//')
          echo "$USED" > /tmp/.opencode_letters
          sed -i "/^${LETTER}:/d" "$LETTER_MAP"
          
          # Open the session
          if [[ -n "$CWD" && -n "$SESSION_NAME" ]]; then
            /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$CWD" "$SESSION_NAME"
          fi
        fi
      fi
    fi
  fi
done
