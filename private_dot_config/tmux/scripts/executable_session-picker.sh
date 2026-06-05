#!/usr/bin/env bash

SCRIPT="$HOME/.config/tmux/scripts/session-picker.sh"

list_sessions() {
  local current
  current=$(tmux display-message -p '#S' 2>/dev/null)
  tmux list-sessions -F '#{session_name}' 2>/dev/null \
    | grep -v '^T2$' \
    | grep -v '^[0-9]*$' \
    | awk -v cur="$current" '{
        print ($0 == cur ? "● " : "○ ") $0
      }'
}

if [ "$1" = "--list" ]; then
  list_sessions
  exit
fi

if [ "$1" = "--rename" ]; then
  old="$2"
  printf 'rename "%s" to: ' "$old"
  read -r new
  [ -n "$new" ] && tmux rename-session -t "$old" "$new"
  exit
fi

if [ "$1" = "--delete" ]; then
  name="$2"
  aoe_id=$(aoe list --json 2>/dev/null | jq -r --arg n "$name" '.[] | select(("aoe_" + .title + "_") as $p | $n | startswith($p)) | .id' | head -1)
  if [ -n "$aoe_id" ]; then
    aoe remove "$aoe_id"
  else
    tmux kill-session -t "$name"
  fi
  exit
fi

list_sessions | fzf \
  --reverse \
  --height=40% \
  --prompt="session: " \
  --header=" enter:switch  D:kill  R:rename  ●=current" \
  --bind "enter:execute-silent(tmux switch-client -t {2})+abort" \
  --bind "D:execute($SCRIPT --delete {2})+reload($SCRIPT --list)" \
  --bind "R:execute($SCRIPT --rename {2})+reload($SCRIPT --list)"
