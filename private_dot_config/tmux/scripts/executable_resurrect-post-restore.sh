#!/usr/bin/env bash
# @resurrect-hook-post-restore-all (see tmux.conf's oh-my-tmux file). Resurrect/
# continuum restore a pane's command and cwd, but not its @role user option, so
# right after a restore every session's active pane is whatever was active when
# it was saved. Re-tag the roles we can recognize by command and refocus+zoom
# claude, matching the layout workspace-init.sh builds for a fresh session.
#
# restore_all_pane_processes() only sends the relaunch keystrokes and does not
# wait for them to land, so immediately after restore most panes are still
# showing their old/default shell. Retry for a couple seconds so this hook
# still converges once claude/nvim/lazygit/k9s actually start.
tmux set-option -gu @restore_in_progress

for attempt in 1 2 3 4 5 6; do
  for s in $(tmux list-sessions -F '#{session_id}' 2>/dev/null); do
    claude=""
    while IFS=$'\t' read -r pane role cmd; do
      case "$cmd" in
        claude)   tmux set-option -p -t "$pane" @role claude; claude="$pane" ;;
        nvim)     tmux set-option -p -t "$pane" @role nvim ;;
        lazygit)  tmux set-option -p -t "$pane" @role git ;;
        k9s)      tmux set-option -p -t "$pane" @role k9s ;;
      esac
    done < <(tmux list-panes -s -t "$s" -F $'#{pane_id}\t#{@role}\t#{pane_current_command}')
    if [ -n "$claude" ]; then
      tmux select-pane -t "$claude"
      # resize-pane -Z TOGGLES zoom; only call it if not already zoomed, so
      # repeat/retry passes stay idempotent instead of flipping it back off
      [ "$(tmux display -p -t "$claude" '#{window_zoomed_flag}')" = 1 ] || tmux resize-pane -t "$claude" -Z
    fi
  done
  sleep 0.3
done
