#!/usr/bin/env bash
# fzf picker over ~/.kube/*.yaml, run inside display-popup (C-b K).
sid=$(tmux display -p '#{session_id}')
cur=$(tmux show -t "$sid" -qv @kube_cluster)
choice=$(ls "$HOME"/.kube/*.yaml 2>/dev/null | xargs -n1 basename | sed 's/\.yaml$//' \
  | grep -v -E '^(kubie|color|__None__)$' \
  | fzf --prompt='cluster> ' --header="current: ${cur:-none}" --height=100% --reverse) || exit 0
[ -n "$choice" ] && exec "$HOME/.config/tmux/scripts/kube-switch.sh" "$choice" -t "$sid"
