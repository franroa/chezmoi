#!/usr/bin/env bash
# Focus + zoom the pane for role $1 (claude|nvim|git|k9s|shell) in the current window.
# Match by @role tag, then by running command (sessions made before the layout
# hook have no tags); if it is missing, open it in a new split. If the pane exists
# but is back at a bare shell (the app exited), relaunch the app in it.
role="$1"
case "$role" in
  claude) cmd=claude; launch='claude --continue --dangerously-skip-permissions' ;;
  nvim)   cmd=nvim; launch=nvim ;;
  git)    cmd=lazygit; launch=lazygit ;;
  k9s)    cmd=k9s; launch=k9s ;;
  shell)  cmd=; launch= ;;   # plain shell: matched by @role tag only
  *) exit 1 ;;
esac
pane=$(tmux list-panes -F '#{pane_id} #{@role}' | awk -v r="$role" '$2 == r { print $1; exit }')
[ -n "$pane" ] || [ -z "$cmd" ] || pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' | awk -v c="$cmd" '$2 == c { print $1; exit }')
if [ -z "$pane" ]; then
  # open in the session's workspace dir, not the active pane's cwd (see workspace-dir.sh)
  dir=$(~/.config/tmux/scripts/workspace-dir.sh)
  pane=$(tmux split-window -h -d -P -F '#{pane_id}' -c "$dir")
  [ -z "$launch" ] || tmux send-keys -t "$pane" "$launch" Enter
elif [ -n "$launch" ]; then
  # Only a foreground shell means the app is not running; checking for a shell
  # (not for $cmd) avoids typing into an app whose process name differs.
  case "$(tmux display -p -t "$pane" '#{pane_current_command}')" in
    bash|zsh|fish|sh|dash) tmux send-keys -t "$pane" "$launch" Enter ;;
  esac
fi
tmux set-option -p -t "$pane" @role "$role"
tmux select-pane -t "$pane"
[ "$(tmux display -p -t "$pane" '#{window_zoomed_flag}')" = 1 ] || tmux resize-pane -t "$pane" -Z
