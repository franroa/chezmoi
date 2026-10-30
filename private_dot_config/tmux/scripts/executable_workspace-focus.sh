#!/usr/bin/env bash
# Focus + zoom the pane for role $1 (claude|nvim|git|k9s|shell) in the current window.
# Match by @role tag (validated against the pane's running command), then by
# running command (sessions made before the layout hook have no tags); if it is missing, open it in a new split. If the pane exists
# but the app is no longer running in it, relaunch the app.
role="$1"
case "$role" in
  claude) cmd=claude; procs='claude|ori'; launch='claude --continue --dangerously-skip-permissions' ;;
  nvim)   cmd=nvim; procs=nvim; launch=nvim ;;
  git)    cmd=lazygit; procs=lazygit; launch=lazygit ;;
  k9s)    cmd=k9s; procs=k9s; launch=k9s ;;
  shell)  cmd=; procs=; launch= ;;   # plain shell: matched by @role tag only
  *) exit 1 ;;
esac
# A @role tag can be stale (resurrect restores panes without their tags, and
# layouts that were saved duplicated get re-tagged in the wrong order), so a tag
# only counts if the pane is running that role's app or a bare shell. A pane
# tagged nvim that is running claude is skipped, not focused.
pf='#{pane_id}|#{@role}|#{pane_current_command}'
panes=$(tmux list-panes -F "$pf")
# with the repo sidebar open, the other panes are parked in a hidden window
parked=$(tmux show -wqv @parked_win)
[ -z "$parked" ] || panes=$(printf '%s\n%s' "$panes" "$(tmux list-panes -t "$parked" -F "$pf" 2>/dev/null)")
pane=$(printf '%s\n' "$panes" | awk -F'|' -v r="$role" -v re="^(${procs:-})$" '
  $2 == r && ($3 ~ /^(bash|zsh|fish|sh|dash)$/ || re == "^()$" || $3 ~ re) { print $1; exit }')
# no usable tag: match by the running command (sessions made before the layout hook)
[ -n "$pane" ] || [ -z "$procs" ] || pane=$(printf '%s\n' "$panes" | awk -F'|' -v re="^($procs)$" '$3 ~ re { print $1; exit }')
if [ -z "$pane" ]; then
  # open in the session's workspace dir, not the active pane's cwd (see workspace-dir.sh)
  dir=$(~/.config/tmux/scripts/workspace-dir.sh)
  # (never split the sidebar itself: target a visible workspace pane)
  anchor=$(tmux list-panes -F '#{pane_id}|#{@role}' | awk -F'|' '$2!="sidebar"{print $1; exit}')
  pane=$(tmux split-window -h -d -P -F '#{pane_id}' -t "$anchor" -c "$dir")
  [ -z "$launch" ] || tmux send-keys -t "$pane" "$launch" Enter
elif [ -n "$launch" ]; then
  # Relaunch only if the pane's foreground is a bare shell AND the app is not
  # anywhere in the pane's process tree. The foreground alone is not enough: while
  # nvim runs `:!cmd` or a plugin job, a shell is briefly in front, and typing the
  # launch command then would land inside the running app.
  case "$(tmux display -p -t "$pane" '#{pane_current_command}')" in
    bash|zsh|fish|sh|dash)
      pid=$(tmux display -p -t "$pane" '#{pane_pid}')
      ps -eo pid=,ppid=,comm= | awk -v root="$pid" -v re="^($procs)$" '
        { kids[$2] = kids[$2] " " $1; comm[$1] = $3 }
        END { n = split(root, q, " "); for (i = 1; i <= n; i++) { cur = q[i]
                m = split(kids[cur], c, " ")
                for (j = 1; j <= m; j++) { if (comm[c[j]] ~ re) found = 1; q[++n] = c[j] } }
              exit !found }' \
        || tmux send-keys -t "$pane" "$launch" Enter ;;
  esac
fi
tmux set-option -p -t "$pane" @role "$role"
tmux select-pane -t "$pane"
# With the repo sidebar open, zoom would hide it: show only this pane next to it.
sb=$(tmux list-panes -F '#{pane_id}|#{@role}' | awk -F'|' '$2=="sidebar"{print $1; exit}')
if [ -n "$sb" ]; then
  ~/.config/tmux/scripts/tmux-sidebar-toggle focus "$pane"
  tmux select-pane -t "$pane"
elif [ "$(tmux display -p -t "$pane" '#{window_zoomed_flag}')" != 1 ]; then
  tmux resize-pane -t "$pane" -Z
fi
