#!/bin/bash
# Called by hyprpanel when a Claude Code notification action button is clicked.
#
# The action id carries the focus target encoded as base64 (see
# ~/.claude/hooks/notify.sh): newline-joined addr, workspace, tmux socket,
# session, window, client. We focus the source conversation directly here — no
# D-Bus ActionInvoked re-broadcast, no notification-id matching.
#
# IMPORTANT: notifications fire for tmux sessions you are NOT currently viewing,
# so the terminal window/address and attached client captured at *send* time are
# stale or empty. Everything window-related is therefore re-resolved LIVE here:
# we ask tmux which client is attached now, switch it to the target session, then
# find that client's terminal window in Hyprland and raise it.
#
# Args: $1 = notification id (unused), $2 = action id.
ACTION_ID="${2:-focus}"

log() { echo "[$(date)] claude-notif-action: $*" >>/tmp/notify-debug.log; }

payload="${ACTION_ID#focus:}"
if [ "$payload" = "$ACTION_ID" ] || [ -z "$payload" ]; then
  log "no encoded payload in action '$ACTION_ID'; nothing to focus"
  exit 0
fi

decoded=$(printf '%s' "$payload" | base64 -d 2>/dev/null)
if [ -z "$decoded" ]; then
  log "failed to decode action payload"
  exit 0
fi

{
  IFS= read -r win_address
  IFS= read -r workspace_info
  IFS= read -r tmux_socket
  IFS= read -r tmux_session
  IFS= read -r tmux_window
  IFS= read -r tmux_client   # captured-at-send; only a fallback hint now
} <<EOF
$decoded
EOF

# hyprctl needs the instance signature; hyprpanel passes it, but guard anyway.
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "/run/user/$(id -u)/hypr/" 2>/dev/null | grep -v '\.' | head -1)
fi

# CRITICAL: hyprpanel spawns us with a nix-flavoured PATH whose `tmux` is an old
# version (e.g. /usr/bin/tmux 3.4). tmux's client/server protocol is version
# locked, so a mismatched client fails with "server exited unexpectedly" or an
# empty list-clients. Always use the binary the running server itself uses.
resolve_tmux_bin() {
  local srv exe c
  srv=$(ps -eo pid=,comm= 2>/dev/null | awk '/tmux: server/{print $1; exit}')
  if [ -n "$srv" ]; then
    exe=$(readlink -f "/proc/$srv/exe" 2>/dev/null)
    [ -x "$exe" ] && { echo "$exe"; return; }
  fi
  for c in /home/linuxbrew/.linuxbrew/bin/tmux "$HOME/.linuxbrew/bin/tmux" tmux; do
    command -v "$c" >/dev/null 2>&1 && { command -v "$c"; return; }
  done
  echo tmux
}
TMUX_BIN=$(resolve_tmux_bin)
log "using tmux binary: $TMUX_BIN ($("$TMUX_BIN" -V 2>/dev/null))"

# Walk a process tree upward to the owning terminal emulator; echo its pid.
find_terminal_pid() {
  local p="$1" comm ppid
  for _ in $(seq 1 10); do
    [ -z "$p" ] && return 1
    comm=$(ps -o comm= -p "$p" 2>/dev/null)
    case "$comm" in
      foot|kitty|alacritty|wezterm|wezterm-gui|ghostty|konsole|xterm|st|rio|gnome-terminal*|gnome-terminal-)
        echo "$p"; return 0;;
    esac
    ppid=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    { [ -z "$ppid" ] || [ "$ppid" -le 1 ]; } && return 1
    p=$ppid
  done
  return 1
}

focus_hypr_addr() {
  local addr="$1"
  [ -z "$addr" ] && return 1
  hyprctl keyword animations:enabled 0 >/dev/null 2>&1
  hyprctl dispatch focuswindow "address:${addr}" >>/tmp/notify-debug.log 2>&1
  local rc=$?
  hyprctl keyword animations:enabled 1 >/dev/null 2>&1
  return $rc
}

log "click target: session=$tmux_session window=$tmux_window socket=$tmux_socket (sent addr=$win_address ws=$workspace_info)"

if [ -n "$tmux_socket" ] && [ -n "$tmux_session" ]; then
  # tmux commands must not inherit a stale $TMUX from hyprpanel's environment.
  unset TMUX
  win="${tmux_window:-0}"

  # Resolve the client attached to this tmux server RIGHT NOW. Prefer the
  # captured one if it is still present, else take the first live client.
  live_clients=$("$TMUX_BIN" -S "$tmux_socket" list-clients -F '#{client_tty}' 2>/dev/null)
  client="$tmux_client"
  if [ -z "$client" ] || ! printf '%s\n' "$live_clients" | grep -qxF "$client"; then
    client=$(printf '%s\n' "$live_clients" | head -n1)
  fi

  if [ -n "$client" ]; then
    "$TMUX_BIN" -S "$tmux_socket" switch-client -c "$client" -t "${tmux_session}:${win}" >>/tmp/notify-debug.log 2>&1
    log "switch-client -c $client -t ${tmux_session}:${win} exit=$?"

    # Find that client's terminal window in Hyprland and raise it.
    cpid=$("$TMUX_BIN" -S "$tmux_socket" display-message -t "$client" -p '#{client_pid}' 2>/dev/null)
    termpid=$(find_terminal_pid "$cpid")
    addr=""
    if [ -n "$termpid" ]; then
      addr=$(hyprctl clients -j 2>/dev/null | jq -r --arg pid "$termpid" '.[] | select(.pid==($pid|tonumber)) | .address' 2>/dev/null | head -n1)
    fi
    if focus_hypr_addr "$addr"; then
      log "raised terminal window addr=$addr (termpid=$termpid)"
    else
      log "could not resolve terminal window (cpid=$cpid termpid=$termpid addr=$addr)"
    fi
  else
    log "no attached tmux client found on $tmux_socket; cannot switch/focus"
  fi
  exit 0
fi

# Non-tmux fallback: use whatever was captured at send time.
if focus_hypr_addr "$win_address"; then
  log "focused by sent addr=$win_address"
elif [ -n "$workspace_info" ]; then
  hyprctl dispatch workspace "$workspace_info" >>/tmp/notify-debug.log 2>&1
  log "switched to workspace=$workspace_info"
else
  log "no focus target available"
fi
