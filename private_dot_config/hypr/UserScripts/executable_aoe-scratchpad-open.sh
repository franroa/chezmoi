#!/usr/bin/env bash
# Script to open aoe session in scratchpad and update current session tracking
# Usage: aoe-scratchpad-open.sh <session-directory> [session-title]

CWD="${1:-}"
SESSION_TITLE="${2:-}"

if [[ -z "$CWD" ]]; then
    echo "Usage: $0 <session-directory> [session-title]"
    exit 1
fi

if [[ ! -d "$CWD" ]]; then
    echo "Error: Directory does not exist: $CWD"
    exit 1
fi

AOE=/home/linuxbrew/.linuxbrew/bin/aoe
PYPR_BIN=/home/froa/.nix-profile/bin/pypr

# Get project name (basename)
PROJECT_NAME=$(basename "$CWD")

# Get current git branch
BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null | tr '/' '-')
[[ -z "$BRANCH" ]] && BRANCH="main"

# If no title provided, use project_branch
if [[ -z "$SESSION_TITLE" ]]; then
    SESSION_TITLE="${PROJECT_NAME}_${BRANCH}"
fi

# Check if the scratchpad is already showing the target session
# Read current session from temp files BEFORE updating them
CURRENT_CWD=""
CURRENT_SESSION=""
if [[ -f /tmp/aoe_cwd_current ]]; then
    CURRENT_CWD=$(cat /tmp/aoe_cwd_current)
fi
if [[ -f /tmp/aoe_session_name ]]; then
    CURRENT_SESSION=$(cat /tmp/aoe_session_name)
fi

# If already showing the target session, check if window is visible
if [[ "$CURRENT_CWD" == "$CWD" || "$CURRENT_SESSION" == "$SESSION_TITLE" ]]; then
    # Check if window exists and is on a normal workspace (not hidden on special)
    WS=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "aoe-cwd") | .workspace.name' 2>/dev/null)
    
    if [[ -n "$WS" && "$WS" != "special:"* ]]; then
        # Window exists and visible - focus directly (fast)
        echo "Session already showing (visible): $SESSION_TITLE"
        hyprctl dispatch focuswindow "class:aoe-cwd" 2>/dev/null
    else
        # Window hidden or doesn't exist - use pypr show (needed for scratchpad behavior)
        echo "Session already showing (hidden): $SESSION_TITLE"
        $PYPR_BIN show aoe
    fi
    exit 0
fi

# Session changed - close and reopen
echo "Switching session: $CURRENT_SESSION → $SESSION_TITLE"
hyprctl dispatch closewindow "class:aoe-cwd" 2>/dev/null || true
sleep 0.2

# Update temp files for session tracking (after the check)
echo "$CWD" > /tmp/aoe_cwd_target
echo "$PROJECT_NAME" > /tmp/aoe_project_name
echo "$BRANCH" > /tmp/aoe_branch_name
echo "$SESSION_TITLE" > /tmp/aoe_session_name
echo "$CWD" > /tmp/aoe_cwd_current
echo "$PROJECT_NAME" > /tmp/aoe_project_current

# Show the scratchpad
$PYPR_BIN show aoe

echo "Opened aoe session: $SESSION_TITLE ($CWD)"
