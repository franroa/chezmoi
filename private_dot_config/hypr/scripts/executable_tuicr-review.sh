#!/usr/bin/env bash
# Wrapper launched inside a fresh ghostty window by the GitLab notification
# "TUI" action button: `ghostty -e tuicr-review.sh <mr>`.
#
# hyprpanel spawns the action command with whatever minimal PATH it inherited,
# so we rebuild a full login-like environment here before running tuicr —
# otherwise tuicr (linuxbrew) or its git/jj subprocesses may not be found.

set -u

export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

mr="${1:-}"
if [[ -z "$mr" ]]; then
    echo "Usage: tuicr-review.sh <mr>" >&2
    echo "Press Enter to close." >&2
    read -r
    exit 2
fi

tuicr pr "$mr"
status=$?

# Keep the window open on failure so the error stays readable.
if [[ $status -ne 0 ]]; then
    echo
    echo "tuicr pr $mr exited with status $status — press Enter to close."
    read -r
fi
