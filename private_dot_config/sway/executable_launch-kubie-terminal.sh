#!/bin/bash
# Launch kubie terminal only if not already running

WORKSPACE="$1"
SCRIPT="$2"
MARKER="/tmp/sway-ws${WORKSPACE}-terminal.pid"
LOCKFILE="/tmp/sway-launch-ws${WORKSPACE}.lock"

# Use flock for atomic locking
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    exit 0
fi

# Check if marker exists and process is still running
if [ -f "$MARKER" ]; then
    PID=$(cat "$MARKER")
    if ps -p "$PID" > /dev/null 2>&1; then
        exit 0
    fi
fi

# Launch terminal and save PID
wezterm start --always-new-process -- "$SCRIPT" &
echo $! > "$MARKER"
sleep 2
