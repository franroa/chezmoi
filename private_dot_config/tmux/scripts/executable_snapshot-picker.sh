#!/usr/bin/env bash
# fzf picker for tmux-named-snapshot: restore / delete named snapshots

SCRIPT="$HOME/.config/tmux/scripts/snapshot-picker.sh"
PLUGIN_DIR="$HOME/.config/tmux/plugins/tmux-named-snapshot/scripts"

resurrect_dir() {
  local opt
  opt=$(tmux show-option -gqv '@resurrect-dir')
  if [ -n "$opt" ]; then
    echo "$opt" | sed "s,\$HOME,$HOME,g; s,~,$HOME,g"
  elif [ -d "$HOME/.local/share/tmux/resurrect" ]; then
    echo "$HOME/.local/share/tmux/resurrect"
  else
    echo "$HOME/.tmux/resurrect"
  fi
}

list_snapshots() {
  local dir
  dir=$(resurrect_dir)
  # named snapshots = symlinks, excluding 'last'
  find "$dir" -maxdepth 1 -type l 2>/dev/null \
    | while read -r f; do basename "$f"; done \
    | grep -v '^last$' \
    | sort
}

if [ "$1" = "--list" ]; then
  list_snapshots
  exit
fi

if [ "$1" = "--delete" ]; then
  rm -f "$(resurrect_dir)/$2"
  exit
fi

sel=$(list_snapshots | fzf \
  --reverse \
  --height=40% \
  --prompt="snapshot: " \
  --header=" enter:restore  D:delete" \
  --bind "D:execute-silent($SCRIPT --delete {})+reload($SCRIPT --list)")

[ -z "$sel" ] && exit 0
"$PLUGIN_DIR/restore-snapshot.sh" "$sel"
