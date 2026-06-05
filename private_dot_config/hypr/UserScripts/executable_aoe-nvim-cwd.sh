#!/usr/bin/env bash

AOE=/home/linuxbrew/.linuxbrew/bin/aoe
FORCE_RESTART="${AOE_FORCE_RESTART:-0}"

# Ensure Homebrew is in PATH (pyprland launches without login shell env)
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
export HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
export HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar
export HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew

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
echo "$CWD" >/tmp/aoe_cwd_current
echo "$PROJECT_NAME" >/tmp/aoe_project_current
echo "$SESSION_TITLE" >/tmp/aoe_session_name

# Check if session exists for this exact title AND path
SESSION_ID=$($AOE list --json 2>/dev/null | jq -r --arg path "$CWD" --arg title "$SESSION_TITLE" '.[] | select(.path == $path and .title == $title) | .id' | head -1)

# Force restart: delete existing session
if [[ "$FORCE_RESTART" == "1" && -n "$SESSION_ID" ]]; then
  $AOE session delete "$SESSION_ID" 2>/dev/null
  SESSION_ID=""
fi

# Write a temp script that foot will execute
SCRIPT=$(mktemp)
chmod +x "$SCRIPT"

if [[ -n "$SESSION_ID" ]]; then
  # Session exists - check its status
  SESSION_STATUS=$($AOE session show --json "$SESSION_ID" 2>/dev/null | jq -r '.status // "stopped"')

  if [[ "$SESSION_STATUS" == "error" ]]; then
    # Session is in error state - delete it and fall through to create a new one
    $AOE session delete "$SESSION_ID" 2>/dev/null
    SESSION_ID=""
  fi
fi

if [[ -n "$SESSION_ID" ]]; then
  if [[ "$SESSION_STATUS" == "running" ]]; then
    # Already running - just attach
    cat >"$SCRIPT" <<EOF
#!/usr/bin/env fish
cd "$CWD"
$AOE session attach "$SESSION_ID"
EOF
  else
    # Not running (stopped or starting) - start it first, then attach
    cat >"$SCRIPT" <<EOF
#!/usr/bin/env fish
cd "$CWD"
$AOE session start "$SESSION_ID"
$AOE session attach "$SESSION_ID"
EOF
  fi
else
  # No session - create new one with project name as title
  cat >"$SCRIPT" <<EOF
#!/usr/bin/env fish
cd "$CWD"
$AOE add "$CWD" --title "$SESSION_TITLE" --cmd opencode --launch
EOF
fi

# foot -e runs the command with a proper TTY
echo "$SCRIPT"
exec foot --app-id=aoe-cwd "$SCRIPT"
