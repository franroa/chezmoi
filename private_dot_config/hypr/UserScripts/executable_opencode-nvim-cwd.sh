#!/usr/bin/env bash

# Read CWD from temp file set by scratchpad-toggle.sh, fallback to $HOME
CWD="$HOME"
if [[ -f /tmp/opencode_cwd_target ]]; then
    TARGET=$(cat /tmp/opencode_cwd_target)
    if [[ -n "$TARGET" && -d "$TARGET" ]]; then
        CWD="$TARGET"
    fi
    rm -f /tmp/opencode_cwd_target
fi

# Store the CWD we're launching with for comparison on next toggle
echo "$CWD" > /tmp/opencode_cwd_current

exec foot --app-id=opencode-cwd -D "$CWD" fish -c '/home/linuxbrew/.linuxbrew/bin/opencode --port --agent plan --continue'
