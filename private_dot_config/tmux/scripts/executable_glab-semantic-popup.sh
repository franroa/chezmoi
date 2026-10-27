#!/usr/bin/env bash
# run-shell target for the which-key "GitLab semantic search" prompts. Args:
# <dir> [-d=<path>] <query...>. tmux word-splits the %% command-prompt
# substitution, so the query arrives as separate args — rejoin with "$*" before
# opening the popup. -d=<path> stays one word even when the path is empty.
set -uo pipefail

dir="$1"
shift
path=""
case "${1:-}" in
  -d=*)
    path="${1#-d=}"
    shift
    ;;
esac
query="$*"
tmux display-popup -E -d "$dir" -h 85% -w 90% "~/.config/tmux/scripts/glab-semantic.sh \"$query\" \"$path\""
