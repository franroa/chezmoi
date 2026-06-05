#!/usr/bin/env bash

sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sort | while read s; do
  [[ "$s" == *-T2 ]] && continue
  [[ "$s" =~ ^[0-9]+$ ]] && continue
  echo "$s"
done)

current=$(tmux display-message -p '#{session_name}')

if [[ "$current" == *-T2 ]]; then
  current="${current%-T2}"
fi

total=$(echo "$sessions" | wc -l)

current_index=$(echo "$sessions" | grep -n "^$current\$" | cut -d: -f1)

if [[ "$1" == "1" ]]; then
  next_index=$((current_index % total + 1))
else
  next_index=$(((current_index - 2 + total) % total + 1))
fi

next_session=$(echo "$sessions" | sed -n "${next_index}p")

if [ -n "$next_session" ]; then
  tmux switch-client -t "$next_session"
  tmux refresh-client
fi
