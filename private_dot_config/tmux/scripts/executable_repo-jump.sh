#!/usr/bin/env bash
# Fuzzy-pick a local GitLab clone under ~/dev/technosylva and open it in a new
# window of the current session (aoe worktrees/workspaces are skipped).
set -uo pipefail

root="$HOME/dev/technosylva"

selected="$(fdfind -t d -H -I --prune -g .git "$root" \
  --exclude .aoe-worktrees --exclude .aoe-workspaces --exclude node_modules \
  -x dirname {} | sed "s|^$root/||" | sort -u | fzf \
    --reverse \
    --prompt="repo: " \
    --preview="git -C $root/{} log --oneline -10 --color=always" \
    --preview-window=right:50%)"

[ -z "$selected" ] && exit 0

tmux new-window -c "$root/$selected" -n "$(basename "$selected")"
