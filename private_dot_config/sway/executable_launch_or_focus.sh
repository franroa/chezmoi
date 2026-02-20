#!/bin/bash
# Switch to workspace and launch app
# Usage: launch_or_focus.sh <workspace> <launch_command>

WORKSPACE="$1"
LAUNCH_CMD="$2"

# Switch to workspace and launch app
swaymsg "workspace number $WORKSPACE"
swaymsg "exec $LAUNCH_CMD"
