#!/usr/bin/env bash
# run-shell target for the which-key "GitLab search" prompt. tmux word-splits
# the %% command-prompt substitution before invoking us, so a multi-word query
# arrives as separate args here — rejoin with "$*" before opening the popup.
set -uo pipefail

query="$*"
tmux display-popup -E -h 85% -w 90% "~/.config/tmux/scripts/glab-search.sh \"$query\""
