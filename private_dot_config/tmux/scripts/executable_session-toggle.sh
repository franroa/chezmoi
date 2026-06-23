#!/usr/bin/env bash

# Cycle the status-bar label mode. Read by tmux-session-list.
#   letters → names → both → letters
#     letters — abbreviate non-focused sessions to a/b/c…
#     names   — full names
#     both    — "<letter>-<name>"

f=/tmp/.claude-tmux-labelmode
case "$(cat "$f" 2>/dev/null)" in
  names) next=both ;;
  both)  next=letters ;;
  *)     next=names ;;   # letters (or unset) → names
esac

printf '%s' "$next" > "$f"
tmux refresh-client -S
