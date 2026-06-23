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

# Find the AOE session backing a tmux session name, across ALL aoe profiles.
# tmux session names are aoe_<title>_<idprefix>, where <idprefix> is the first 8
# chars of the AOE session id. `aoe list` only sees the default profile, so we
# must iterate every profile. Echoes "<profile>\t<id>" and returns 0 if found.
find_aoe() {
  local name="$1" idpfx prof id pdir
  idpfx="${name##*_}"
  pdir="${XDG_CONFIG_HOME:-$HOME/.config}/agent-of-empires/profiles"
  while IFS= read -r prof; do
    [ -n "$prof" ] || continue
    id=$(aoe -p "$prof" list --json 2>/dev/null \
      | jq -r --arg p "$idpfx" --arg n "$name" \
          '.[] | select((.id|startswith($p)) or (("aoe_"+.title+"_") as $x | $n|startswith($x))) | .id' \
          2>/dev/null \
      | head -1)
    if [ -n "$id" ]; then printf '%s\t%s\n' "$prof" "$id"; return 0; fi
  done < <(find "$pdir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)
  return 1
}

case "$1" in
  --list)
    list_sessions; exit ;;
  --rename)
    old="$2"
    printf 'rename "%s" to: ' "$old"
    read -r new
    [ -n "$new" ] && tmux rename-session -t "$old" "$new"
    exit ;;
  --kill|--close)
    # CLOSE: tear down the tmux session only; leave the AOE session record alive.
    name="$2"
    tmux kill-session -t "$name" 2>/dev/null
    exit ;;
  --remove|--delete)
    # CLOSE + REMOVE FROM AOE: find the backing aoe session in any profile and
    # `aoe remove` it (which also tears down its container/tmux); fall back to a
    # plain kill if it isn't an aoe-managed session.
    name="$2"
    if found=$(find_aoe "$name"); then
      prof=${found%%$'\t'*}; id=${found##*$'\t'}
      aoe -p "$prof" remove "$id" >/dev/null 2>&1
    fi
    tmux has-session -t "$name" 2>/dev/null && tmux kill-session -t "$name" 2>/dev/null
    exit ;;
esac

list_sessions | fzf \
  --reverse \
  --height=40% \
  --prompt="session: " \
  --header=" enter:switch  D:close  X:close+aoe-rm  R:rename  ●=current" \
  --bind "enter:execute-silent(tmux switch-client -t {2})+abort" \
  --bind "D:execute-silent($SCRIPT --kill {2})+reload($SCRIPT --list)" \
  --bind "X:execute-silent($SCRIPT --remove {2})+reload($SCRIPT --list)" \
  --bind "R:execute($SCRIPT --rename {2})+reload($SCRIPT --list)"
