#!/usr/bin/env bash
# Print the workspace (project) directory for a tmux session and cache it in
# the session option @workspace_dir. Every pane split by workspace-init.sh /
# workspace-focus.sh is opened here, so all panes share one cwd.
#   workspace-dir.sh [-t <session>]
# aoe creates its sessions in $HOME and only `cd`s the claude pane into the
# project afterwards, so pane_current_path/session_path are wrong at hook time;
# the authoritative path is project_path in aoe's profiles/*/sessions.json,
# looked up by the id prefix at the end of the session name (aoe_<title>_<id>).
target=""
[ "$1" = -t ] && target="$2"
[ -n "$target" ] || target=$(tmux display -p '#{session_id}')

dir=$(tmux show -t "$target" -qv @workspace_dir)
if [ -z "$dir" ] || [ ! -d "$dir" ]; then
  dir=""
  name=$(tmux display -p -t "$target" '#{session_name}')
  case "$name" in
    aoe_*_*)
      idpfx="${name##*_}"
      for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/agent-of-empires/profiles/*/sessions.json; do
        [ -f "$f" ] || continue
        dir=$(jq -r --arg p "$idpfx" '.[] | select(.id|startswith($p)) | .project_path' "$f" 2>/dev/null | head -1)
        [ -n "$dir" ] && [ -d "$dir" ] && break
        dir=""
      done ;;
  esac
fi
if [ -z "$dir" ]; then
  # not an aoe session: the claude pane's cwd, else the first pane's cwd, else session_path
  dir=$(tmux list-panes -s -t "$target" -F '#{@role} #{pane_current_path}' | awk '$1=="claude"{print $2; exit}')
  [ -n "$dir" ] || dir=$(tmux list-panes -s -t "$target" -F '#{pane_current_path}' | head -1)
  [ -n "$dir" ] || dir=$(tmux display -p -t "$target" '#{session_path}')
fi
[ -n "$dir" ] && [ -d "$dir" ] || dir="$HOME"
tmux set-option -t "$target" @workspace_dir "$dir"
printf '%s\n' "$dir"
