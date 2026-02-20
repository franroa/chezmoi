#!/usr/bin/env bash

AOE=/home/linuxbrew/.linuxbrew/bin/aoe
FORCE_RESTART="${AOE_FORCE_RESTART:-0}"

# Get CWD from temp file (set by scratchpad-toggle.sh)
CWD="$HOME"
[[ -f /tmp/aoe_cwd_target ]] && CWD=$(cat /tmp/aoe_cwd_target)
[[ ! -d "$CWD" ]] && CWD="$HOME"

# Get project name (set by scratchpad-toggle.sh)
PROJECT_NAME=""
[[ -f /tmp/aoe_project_name ]] && PROJECT_NAME=$(cat /tmp/aoe_project_name)
[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME=$(basename "$CWD")

# Get current git branch (if in a git repo)
BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null | tr '/' '-')
[[ -z "$BRANCH" ]] && BRANCH="main"

# Session title: project_branch (e.g., platform-core_feature-add_backup)
SESSION_TITLE="${PROJECT_NAME}_${BRANCH}"

# Check for force restart flag
if [[ -f /tmp/aoe_force_restart ]]; then
    FORCE_RESTART=1
    rm -f /tmp/aoe_force_restart
fi

# Store current CWD and project name for toggle comparison
echo "$CWD" > /tmp/aoe_cwd_current
echo "$PROJECT_NAME" > /tmp/aoe_project_current
echo "$SESSION_TITLE" > /tmp/aoe_session_name

# Check if session exists for this path (by path, not title)
SESSION_ID=$($AOE list --json 2>/dev/null | jq -r --arg path "$CWD" '.[] | select(.path == $path) | .id' | head -1)

# Force restart: delete existing session
if [[ "$FORCE_RESTART" == "1" && -n "$SESSION_ID" ]]; then
    $AOE session delete "$SESSION_ID" 2>/dev/null
    SESSION_ID=""
fi

# Write a temp script that foot will execute
SCRIPT=$(mktemp)
chmod +x "$SCRIPT"

if [[ -n "$SESSION_ID" ]]; then
    # Session exists - get its title and construct tmux session name
    TITLE=$($AOE list --json 2>/dev/null | jq -r --arg id "$SESSION_ID" '.[] | select(.id == $id) | .title' | head -1)
    TITLE=${TITLE:-"$SESSION_TITLE"}  # Fallback to project name if no title
    TITLE=${TITLE//\//-}  # Replace / with - to avoid tmux session name issues
    TMUX_SESSION="aoe_${TITLE}_${SESSION_ID:0:8}"
    
    # Start the session
    $AOE session start "$SESSION_ID" 2>/dev/null
    
    # Open foot - user can manually attach with: tmux attach -t $TMUX_SESSION
    # Or use the aoe command which handles TTY better when run interactively
    cat > "$SCRIPT" << EOF
#!/usr/bin/env bash
cd "$CWD"
echo "Session: $TITLE"
echo "To attach to tmux, run: tmux attach -t $TMUX_SESSION"
echo ""
    # Try to attach - will work if run interactively
    # If attach fails (non-TTY), fall back to running aoe add to ensure opencode launches
    $AOE session attach "$SESSION_ID" 2>/dev/null || exec $AOE session start "$SESSION_ID" && exec $AOE session attach "$SESSION_ID"
EOF
else
    # No session - create new one with project name as title
    cat > "$SCRIPT" << EOF
#!/usr/bin/env bash
cd "$CWD"
exec $AOE add "$CWD" --title "$SESSION_TITLE" --cmd opencode --launch
EOF
fi

# foot -e runs the command with a proper TTY
exec foot --app-id=aoe-cwd "$SCRIPT"
