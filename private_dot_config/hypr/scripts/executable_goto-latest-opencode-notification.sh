#!/bin/bash
# Go to the source of the latest OpenCode notification

# Read latest notification session from temp files
CWD=$(cat /tmp/aoe_latest_notif_cwd 2>/dev/null)
SESSION=$(cat /tmp/aoe_latest_notif_session 2>/dev/null)

if [[ -n "$CWD" && -n "$SESSION" ]]; then
    /home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh "$CWD" "$SESSION"
else
    # Fallback: just open aoe scratchpad with current session
    /home/froa/.config/hypr/scripts/scratchpad-toggle.sh aoe
fi
