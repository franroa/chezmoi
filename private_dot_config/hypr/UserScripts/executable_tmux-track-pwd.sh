#!/bin/bash
exec 2>/dev/null
ACTION="$1"

SESSION=$(tmux display-message -p '#S')

# Debug logging (comment out for production)
# echo "$(date): Starting tmux-track-pwd.sh with action=$ACTION" >>/tmp/tmux-track-debug.log
# echo "SESSION=$SESSION" >>/tmp/tmux-track-debug.log

# Switch foot terminal to shadow session when session changes in Ghostty
if [ "$ACTION" = "switch" ] || [ "$ACTION" = "attach" ]; then
  FOOT_APP_ID="aoe-cwd"
  SHADOW_SESSION="${SESSION}-T2"

  # Check if shadow session exists
  if tmux has-session -t "$SHADOW_SESSION" 2>/dev/null; then
    # Check if foot window already exists in Hyprland
    EXISTING=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"$FOOT_APP_ID\") | .address" 2>/dev/null)

    if [ -z "$EXISTING" ]; then
      # No foot window exists - create new one
      foot -a "$FOOT_APP_ID" -- tmux attach -t "$SHADOW_SESSION" &>/dev/null &
      sleep 0.5
    fi
    # If foot already exists, leave it as is - don't close/recreate
  fi
fi

PATH_INFO=$(tmux display-message -p '#{pane_current_path}' 2>>/tmp/tmux-track-debug.log)
echo "PATH_INFO=$PATH_INFO" >>/tmp/tmux-track-debug.log

GIT_ROOT=$(cd "$PATH_INFO" && git rev-parse --git-common-dir 2>/dev/null | xargs dirname 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || echo "")
echo "GIT_ROOT=$GIT_ROOT" >>/tmp/tmux-track-debug.log

if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.envrc" ]; then
  echo "Found .envrc in $GIT_ROOT, sourcing..." >>/tmp/tmux-track-debug.log
  . "$GIT_ROOT/.envrc" 2>/dev/null
  echo "GIT_WORK_TREE after source: $GIT_WORK_TREE" >>/tmp/tmux-track-debug.log
  if [ -n "$GIT_WORK_TREE" ] && [ -d "$GIT_WORK_TREE" ]; then
    echo "Using GIT_WORK_TREE=$GIT_WORK_TREE from .envrc" >>/tmp/tmux-track-debug.log
    PATH_INFO="$GIT_WORK_TREE"
  fi
fi

if [ -z "$PATH_INFO" ]; then
  echo "No PATH_INFO, exiting" >>/tmp/tmux-track-debug.log
  exit 0
fi

NVIM_ROOT=$(cd "$PATH_INFO" && nvim --headless +'lua print(LazyVim.root.get())' +q 2>&1 | grep -v '^$' | tail -1)
echo "NVIM_ROOT=$NVIM_ROOT" >>/tmp/tmux-track-debug.log

if [ "$ACTION" = "new" ]; then
  echo "Storing path $PATH_INFO for session $SESSION" >>/tmp/tmux-track-debug.log
  echo "$PATH_INFO" >"/tmp/tmux_session_path_$SESSION"
elif [ "$ACTION" = "attach" ] || [ "$ACTION" = "switch" ]; then
  if [ -n "$NVIM_ROOT" ] && [ "$NVIM_ROOT" != "nil" ] && [ "$NVIM_ROOT" != "null" ]; then
    echo "Writing $NVIM_ROOT to last_nvim_root" >>/tmp/tmux-track-debug.log
    echo "$NVIM_ROOT" >/tmp/last_nvim_root
  else
    echo "No NVIM_ROOT, falling back to git root detection" >>/tmp/tmux-track-debug.log
    GIT_ROOT=$(cd "$PATH_INFO" && git rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$GIT_ROOT" ]; then
      echo "Writing $GIT_ROOT to last_nvim_root" >>/tmp/tmux-track-debug.log
      echo "$GIT_ROOT" >/tmp/last_nvim_root
    else
      echo "No git root, using PATH_INFO" >>/tmp/tmux-track-debug.log
      echo "$PATH_INFO" >/tmp/last_nvim_root
    fi
  fi
fi
