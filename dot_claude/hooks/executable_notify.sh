#!/usr/bin/env bash
# Claude Code notifications for Hyprland
# Usage: notify.sh <message> [sound_file]

PLUGIN_ROOT="/home/froa/.claude/plugins/cache/claude-notifications-go/claude-notifications-go/1.38.0"
ICON="${PLUGIN_ROOT}/claude_icon.png"

# --- Suppress when workspace 1 is focused ---
# If the user is already looking at workspace 1, skip the notification entirely.
if command -v hyprctl &>/dev/null; then
  active_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' 2>/dev/null)
  [ "$active_ws" = "1" ] && exit 0
fi

# --- Git repo name ---
repo_name=""
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  [ -n "$repo_root" ] && repo_name=$(basename "$repo_root")
fi

# --- tmux session capture (for window/pane restore on click) ---
tmux_socket=""
tmux_session=""
tmux_window=""
tmux_client=""
if [ -n "$TMUX" ]; then
  tmux_socket=$(echo "$TMUX" | cut -d',' -f1)
  tmux_session=$(tmux display-message -p '#S' 2>/dev/null | tr -d ' ')
  tmux_window=$(tmux display-message -p '#I' 2>/dev/null | tr -d ' ')
  tmux_client=$(tmux display-message -p '#{client_tty}' 2>/dev/null | tr -d ' ')
fi

# --- Hyprland workspace + window detection ---
workspace_info=""
win_address=""
if command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
  # If inside tmux, walk up from the tmux client PID to find the terminal emulator.
  # Direct walk from $$ fails because tmux server daemonizes (reparents to systemd).
  if [ -n "$TMUX" ]; then
    term_pid=$(tmux display-message -p '#{client_pid}' 2>/dev/null | tr -d ' ')
    [ -z "$term_pid" ] && term_pid=$$
  else
    term_pid=$$
  fi

  while [ "$term_pid" -gt 1 ]; do
    parent_pid=$(ps -o ppid= -p "$term_pid" 2>/dev/null | tr -d ' ')
    [ -z "$parent_pid" ] && break
    parent_name=$(ps -o comm= -p "$parent_pid" 2>/dev/null)
    if [[ "$parent_name" =~ ^(foot|kitty|alacritty|wezterm|ghostty|konsole|xterm|gnome-terminal) ]]; then
      term_pid=$parent_pid
      break
    fi
    term_pid=$parent_pid
  done

  win_json=$(hyprctl clients -j 2>/dev/null |
    jq --arg pid "$term_pid" '[.[] | select(.pid == ($pid | tonumber))] | .[0] // empty' 2>/dev/null)

  if [ -n "$win_json" ] && [ "$win_json" != "null" ]; then
    ws_name=$(echo "$win_json" | jq -r '.workspace.name // empty')
    [ -n "$ws_name" ] && workspace_info="$ws_name"
    win_address=$(echo "$win_json" | jq -r '.address // empty')
  fi
fi

# --- Build body ---
message="${1:-Task completed}"
context=""
[ -n "$workspace_info" ] && context="$workspace_info"
if [ -n "$repo_name" ]; then
  [ -n "$context" ] && context="${context} · ${repo_name}" || context="$repo_name"
fi
body="$message"
[ -n "$context" ] && body="${context}\n${message}"

# --- Play sound (non-blocking) ---
sound_file="${2:-${PLUGIN_ROOT}/sounds/task-complete.mp3}"
if [ -f "$sound_file" ]; then
  ffplay -nodisp -autoexit -loglevel quiet "$sound_file" &>/dev/null &
fi

# --- Debug log ---
echo "[$(date)] tmux_socket=$tmux_socket tmux_session=$tmux_session tmux_window=$tmux_window tmux_client=$tmux_client win_address=$win_address workspace_info=$workspace_info" >>/tmp/notify-debug.log

# --- Send notification (non-blocking, click-to-focus self-contained) ---
# Previously this used `notify-send --action ... --print-id`, which BLOCKS until
# the action fires and required re-broadcasting a D-Bus ActionInvoked signal back
# to this process on click. That was unreliable: libastal-notifd reuses
# notification ids (and resets them on every hyprpanel restart), so the broadcast
# — matched only by numeric id — was intercepted by stale blocked listeners,
# leaking processes and focusing the wrong (or no) session.
#
# Instead we send via a direct gdbus Notify (returns immediately, no blocked
# process) and encode the focus target directly into the action key. The click
# handler (claude-notif-action.sh) decodes it and focuses directly. Nothing
# depends on notification-id matching anymore.
body_expanded=$(printf '%b' "$body")

# Encode focus context into the action key: newline-joined, base64 (no quotes/
# whitespace/glob chars), so it survives the bash -c hop in the hyprpanel bundle.
focus_payload=$(printf '%s\n%s\n%s\n%s\n%s\n%s' \
  "$win_address" "$workspace_info" "$tmux_socket" "$tmux_session" "$tmux_window" "$tmux_client" |
  base64 -w0)
action_key="focus:${focus_payload}"

notif_id=$(gdbus call --session \
  --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.Notify \
  "Claude Code" 0 "$ICON" "Claude Code" "$body_expanded" \
  "['${action_key}', 'Go to session']" \
  '{"urgency": <byte 1>}' 'int32 -1' 2>>/tmp/notify-debug.log |
  grep -oE '[0-9]+' | head -n1)

echo "[$(date)] sent notif_id=$notif_id target_session=$tmux_session target_window=$tmux_window target_addr=$win_address" >>/tmp/notify-debug.log
