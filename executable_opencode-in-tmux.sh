#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-notify.sh"

# 1. Detect the current session name
CURRENT_SESSION=$(tmux display-message -p '#{session_name}')

# Safety check: ensure we are actually inside a tmux session
if [ -z "$CURRENT_SESSION" ]; then
  echo "Error: You must run this script from inside a tmux session."
  exit 1
fi

# Prevent running the script from an already shadowed session
if [[ "$CURRENT_SESSION" =~ -T2$ ]]; then
  exit 0
fi

SHADOW_SESSION="${CURRENT_SESSION}-T2"
FOOT_APP_ID="aoe-cwd"

# 2. Check if the Shadow Session already exists
if ! tmux has-session -t "$SHADOW_SESSION" 2>/dev/null; then
  sleep 0.5

  # Get current working directory after plugin has changed the path
  CURRENT_PWD=$(tmux display-message -p '#{pane_current_path}')

  # 3. Create the Shadow Session grouped with the current one
  tmux new-session -d -t "$CURRENT_SESSION" -s "$SHADOW_SESSION" -c "$CURRENT_PWD"

  # 4. Create the 'opencode' window specifically in the Master's pool
  tmux new-window -d -t "$CURRENT_SESSION" -n "code" -c "$CURRENT_PWD"

  # 5. Force ONLY the Shadow session to focus on the 'code' window
  tmux select-window -t "${SHADOW_SESSION}:code"
fi

# 6. Check if foot window already exists and close it
EXISTING_WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$FOOT_APP_ID\") | .address" 2>/dev/null)

if [ -n "$EXISTING_WINDOW" ]; then
  # Close existing foot window
  hyprctl dispatch closewindow "address:$EXISTING_WINDOW" >/dev/null 2>&1
  sleep 0.2
fi

# Create new foot window with the shadow session
foot -a "$FOOT_APP_ID" -- tmux attach -t "$SHADOW_SESSION" &>/dev/null &
sleep 0.5

# Ensure window is on workspace 99 (hidden, silent)
WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$FOOT_APP_ID\") | .address" 2>/dev/null)
if [ -n "$WINDOW" ]; then
  hyprctl dispatch movetoworkspacesilent "99,address:$WINDOW"
fi

notify_session "$SHADOW_SESSION" >/dev/null 2>&1

exit 0
