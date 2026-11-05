#!/usr/bin/env bash
# Focus + zoom the pane for role $1 (claude|nvim|git|k9s|shell) in the current window.
# Match by @role tag (validated against the pane's running command), then by
# running command (sessions made before the layout hook have no tags); if it is missing, open it in a new split. If the pane exists
# but the app is no longer running in it, relaunch the app.
role="$1"
case "$role" in
  claude) cmd=claude; procs='claude|ori'; launch='claude --continue --dangerously-skip-permissions --advisor opus' ;;
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
# One ps + one tmux call for the whole run: TREE[pane_id] = space-separated comms
# of every descendant of that pane's root process.
declare -A TREE CMD TAG
while IFS='|' read -r id pid cmd tag; do
  CMD[$id]=$cmd; TAG[$id]=$tag; ROOTS+="$id:$pid "
done < <(tmux list-panes -s -F '#{pane_id}|#{pane_pid}|#{pane_current_command}|#{@role}')
while read -r id comms; do TREE[$id]=$comms; done < <(
  ps -eo pid=,ppid=,comm= | awk -v roots="$ROOTS" '
    { kids[$2] = kids[$2] " " $1; comm[$1] = $3 }
    END { n = split(roots, r, " ")
          for (k = 1; k <= n; k++) { split(r[k], x, ":"); out = ""; q[1] = x[2]; h = 1; t = 1
            while (h <= t) { m = split(kids[q[h]], c, " ")
              for (j = 1; j <= m; j++) { out = out " " comm[c[j]]; q[++t] = c[j] }; h++ }
            print x[1], out } }')
# has_proc PANE REGEX: any descendant of the pane's root process matches REGEX
has_proc() { local c; for c in ${TREE[$1]}; do [[ $c =~ ^($2)$ ]] && return 0; done; return 1; }
apps='claude|ori|nvim|lazygit|k9s|node'
# a shell-foreground pane only counts as "bare" if no other app runs under it
# (claude launched via a wrapper script shows cmd=bash but still owns the pane)
is_bare() {
  case "${CMD[$1]}" in
    bash|zsh|fish|sh|dash) ! has_proc "$1" "$apps" ;;
    *) return 1 ;;
  esac
}
# shell role: a pane counts if no other role's app owns it. A long-running command
# (make, tail, ...) in the command pane must not make it look "taken", or the key
# would open a fresh split instead of returning to it.
is_shellish() { [ -z "$(app_role "$1")" ] && [[ ${CMD[$1]} =~ ^(bash|zsh|fish|sh|dash)$ || -n ${TREE[$1]// /} ]]; }
# Self-heal stale @role tags (resurrect/aoe restores re-tag panes wrongly): a pane
# running a known app is re-tagged with that app's role; a tag that contradicts the
# running app is dropped. Applies to all five roles.
app_role() {  # echo the role of the app running in pane $1, if any
  local c=${CMD[$1]}
  if   [[ $c =~ ^(claude|ori)$ ]] || { [[ ! $c =~ ^(nvim|lazygit|k9s)$ ]] && has_proc "$1" 'claude|ori'; }; then echo claude
  elif [ "$c" = nvim ]    || has_proc "$1" nvim;    then echo nvim
  elif [ "$c" = lazygit ] || has_proc "$1" lazygit; then echo git
  elif [ "$c" = k9s ]     || has_proc "$1" k9s;     then echo k9s
  fi
}
for p in $(tmux list-panes -F '#{pane_id}'); do
  cur=${TAG[$p]}; [ "$cur" = sidebar ] && continue
  det=$(app_role "$p")
  if [ -n "$det" ]; then
    [ "$cur" = "$det" ] || { tmux set-option -p -t "$p" @role "$det"; TAG[$p]=$det; }
  elif [ -n "$cur" ] && [ "$cur" != shell ] && ! is_bare "$p"; then
    tmux set-option -pu -t "$p" @role; TAG[$p]=
  fi
done
pf='#{pane_id}|#{@role}|#{pane_current_command}'
panes=$(tmux list-panes -F "$pf")
# with the repo sidebar open, the other panes are parked in a hidden window
parked=$(tmux show -wqv @parked_win)
[ -z "$parked" ] || panes=$(printf '%s\n%s' "$panes" "$(tmux list-panes -t "$parked" -F "$pf" 2>/dev/null)")
# Prefer the pane this role last focused in this window (several panes can carry
# the same tag after restores; without this, the cd'd-into pane is not the one
# picked again). Remembered per window in @last_<role>.
pane=
last=$(tmux show -wqv "@last_$role")
if [ -n "$last" ] && [ -n "${CMD[$last]}" ]; then
  if [ -z "$procs" ]; then is_shellish "$last" && pane=$last
  elif [ "${TAG[$last]}" = "$role" ]; then pane=$last
  fi
fi
while [ -z "$pane" ] && IFS='|' read -r id tag cur; do
  [ "$tag" = "$role" ] || continue
  if [ -z "$procs" ]; then is_shellish "$id" && { pane=$id; break; }     # shell role: bare shells only
  elif printf '%s' "$cur" | grep -Eq "^($procs)$" || is_bare "$id"; then pane=$id; break
  fi
done <<< "$panes"
# no usable tag: match by the running command (sessions made before the layout hook)
[ -n "$pane" ] || [ -z "$procs" ] || pane=$(printf '%s\n' "$panes" | awk -F'|' -v re="^($procs)$" '$3 ~ re { print $1; exit }')
# shell role: reuse any bare shell pane no other role owns before splitting
if [ -z "$pane" ] && [ "$role" = shell ]; then
  for id in $(tmux list-panes -F '#{pane_id}'); do
    [ -z "${TAG[$id]}" ] && is_bare "$id" && { pane=$id; break; }
  done
fi
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
  ! is_bare "$pane" || tmux send-keys -t "$pane" "$launch" Enter
fi
tmux set-option -p -t "$pane" @role "$role"
tmux set-option -w "@last_$role" "$pane"
tmux select-pane -t "$pane"
# With the repo sidebar open, zoom would hide it: show only this pane next to it.
sb=$(tmux list-panes -F '#{pane_id}|#{@role}' | awk -F'|' '$2=="sidebar"{print $1; exit}')
if [ -n "$sb" ]; then
  ~/.config/tmux/scripts/tmux-sidebar-toggle focus "$pane"
  tmux select-pane -t "$pane"
elif [ "$(tmux display -p -t "$pane" '#{window_zoomed_flag}')" != 1 ]; then
  tmux resize-pane -t "$pane" -Z
fi
