#!/bin/bash

# Tmux session notification module
# This module notifies other terminals (e.g., foot) when tmux sessions are created or switched
# Source this file: source /path/to/tmux-notify.sh

NOTIFY_FILE="${TMUX_NOTIFY_FILE:-/tmp/tmux-current-session}"

notify_session() {
  local session_name="$1"
  echo "$session_name" > "$NOTIFY_FILE"
}

notify_session_switch() {
  local current_session
  current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
  if [ -n "$current_session" ]; then
    notify_session "$current_session"
  fi
}

create_session_watcher() {
  cat << 'EOF'
# Tmux session watcher - run this in foot to auto-switch sessions
watch_session() {
  local notify_file="${TMUX_NOTIFY_FILE:-/tmp/tmux-current-session}"
  touch "$notify_file"
  
  if command -v inotifywait &>/dev/null; then
    while inotifywait -q -e modify "$notify_file" 2>/dev/null; do
      session=$(cat "$notify_file")
      if [ -n "$session" ]; then
        tmux switch-client -t "$session" 2>/dev/null
      fi
    done
  else
    local last_session=""
    while true; do
      session=$(cat "$notify_file" 2>/dev/null)
      if [ -n "$session" ] && [ "$session" != "$last_session" ]; then
        tmux switch-client -t "$session" 2>/dev/null
        last_session="$session"
      fi
      sleep 0.3
    done
  fi
}
EOF
}

start_session_watcher() {
  local notify_file="${TMUX_NOTIFY_FILE:-/tmp/tmux-current-session}"
  touch "$notify_file"
  
  local last_session=""
  while true; do
    session=$(cat "$notify_file" 2>/dev/null)
    if [ -n "$session" ] && [ "$session" != "$last_session" ]; then
      tmux switch-client -t "$session" 2>/dev/null
      last_session="$session"
    fi
    sleep 0.3
  done
}

if [ "${TMUX_NOTIFY_SOURCE_ONLY:-0}" = "1" ]; then
  return 0
fi

if [ -n "$TMUX" ]; then
  notify_session_switch
fi
