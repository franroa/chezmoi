#!/usr/bin/env bash
# @resurrect-hook-post-restore-all (see tmux.conf's oh-my-tmux file).
# Resurrect restores panes but not their @role tags, and it adds the saved panes
# on top of whatever a session already has, so restoring a save that held
# duplicates (or a `_parked` sidebar window) made every restart worse and left
# C-b o/e/g focusing the wrong panes. Instead of patching that layout, rebuild
# each restored session from scratch: keep its first pane, drop everything else
# and run workspace-init.sh, which starts claude/nvim/lazygit/k9s fresh.
# @resurrect-processes is 'false', so restored panes are bare shells. Sessions
# that already run claude (live before a manual C-b r restore) are left alone.
tmux set-option -gu @restore_in_progress

for s in $(tmux list-sessions -F '#{session_id}' 2>/dev/null); do
  name=$(tmux display -p -t "$s" '#{session_name}')
  case "$name" in __tmux__jot_*|scratch-*) continue ;; esac
  tmux list-panes -s -t "$s" -F '#{pane_current_command}' | grep -qxE 'claude|ori' && continue
  # sidebar leftovers: the parked panes, the sidebar pane and its window options
  for w in $(tmux list-windows -t "$s" -F '#{window_id}|#{window_name}' | awk -F'|' '$2=="_parked"{print $1}'); do
    tmux kill-window -t "$w"
  done
  win=$(tmux list-windows -t "$s" -F '#{window_id}' | head -1)
  for o in @parked_win @sb_layout @sb_order; do tmux set-option -w -u -t "$win" "$o" 2>/dev/null; done
  keep=$(tmux list-panes -t "$win" -F '#{pane_id}' | head -1)
  tmux kill-pane -a -t "$keep"
  tmux set-option -p -u -t "$keep" @role
  ~/.config/tmux/scripts/workspace-init.sh -t "$s"
done
