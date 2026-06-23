#!/usr/bin/env bash
# Launch gctui inside a tmux popup. If it exits abnormally — non-zero status, or
# in under a second (the "popup flashes and closes" case) — keep the popup open
# and show stderr, so failures are never silent.
#
# Usage: gctui-popup.sh [gctui flags] [repo]
set -uo pipefail

bin="$HOME/.local/bin/gctui"
log="${XDG_CACHE_HOME:-$HOME/.cache}/gctui/popup.log"
mkdir -p "$(dirname "$log")"
: > "$log"

start=$SECONDS
"$bin" "$@" 2> >(tee "$log" >&2)
rc=$?
dur=$((SECONDS - start))

if [ "$rc" -ne 0 ] || [ "$dur" -lt 1 ]; then
	printf '\n\033[1;33mgctui exited rc=%s after %ss\033[0m\n' "$rc" "$dur"
	if [ -s "$log" ]; then
		echo "── stderr ─────────────────────────────"
		cat "$log"
	else
		echo "(no stderr captured — likely an immediate clean exit / input issue)"
	fi
	read -rp "press enter to close" _
fi
