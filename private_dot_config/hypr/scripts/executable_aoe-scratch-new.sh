#!/usr/bin/env bash
# Prompt for a session name via rofi, create a new aoe scratch session running
# claude, then open it in the aoe-cwd foot scratchpad and reveal it on the
# current workspace. Triggered from wlr-which-key (leader -> o -> A).

LOG=/tmp/aoe-scratch-new.log
log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; }

log "=== invoked (PATH=$PATH) ==="

# Make sure common binary locations are on PATH (wlr-which-key/rofi spawn
# commands with a minimal environment that may miss brew / nix / cargo paths).
export PATH="/home/linuxbrew/.linuxbrew/bin:$HOME/.nix-profile/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

AOE=/home/linuxbrew/.linuxbrew/bin/aoe
[[ -x "$AOE" ]] || AOE=$(command -v aoe)

if [[ -z "$AOE" ]]; then
    log "ERROR: aoe binary not found"
    notify-send -u critical "AOE Scratchpad" "aoe binary not found"
    exit 1
fi
log "using aoe: $AOE"

# Rofi theme (reuse the search theme used elsewhere in this config)
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='Enter a name for the new aoe scratchpad session'

# Kill any stray rofi before launching
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# Prompt for the session name
session_name=$(printf '' | rofi -dmenu -config "$rofi_theme" -mesg "$msg" -p "Session name")
log "session_name='$session_name'"

# Bail out if cancelled / empty
if [[ -z "$session_name" ]]; then
    log "cancelled / empty, exiting"
    exit 0
fi

# All scratchpad sessions get an "SP-" prefix (don't double it up if the user
# already typed one).
session_name="${session_name#SP-}"
session_title="SP-${session_name}"
log "session_title='$session_title'"

# 1. Create the scratch session (registers it; does NOT start tmux or open a
#    window on its own - `aoe add` only prints "Next steps").
add_out=$("$AOE" add --scratch -t "$session_title" -c claude 2>&1)
log "add output:"
log "$add_out"

# Parse the session id from the "ID:   <id>" line aoe prints.
sid=$(awk '/^[[:space:]]*ID:[[:space:]]/{print $2; exit}' <<<"$add_out")
if [[ -z "$sid" ]]; then
    log "ERROR: could not parse session id from aoe add output"
    notify-send -u critical "AOE Scratchpad" "Failed to create session '$session_title'"
    exit 1
fi
log "created session id=$sid"

# 2. Replace any existing scratchpad window so it shows the new session
#    (the aoe-cwd scratchpad only ever holds one session at a time).
hyprctl dispatch closewindow "class:aoe-cwd" 2>/dev/null || true
sleep 0.2

# 3. Write the script foot will run: start the session's tmux, then attach.
attach_script=$(mktemp /tmp/aoe-scratch-XXXXXX.fish)
chmod +x "$attach_script"
cat >"$attach_script" <<EOF
#!/usr/bin/env fish
$AOE session start $sid
$AOE session attach $sid
EOF

# Remember the workspace to reveal on. The aoe-cwd window rule throws every
# aoe-cwd window onto ws 99 ("silent"), so we pull it back to the active one.
target_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
[[ -z "$target_ws" || "$target_ws" == "null" ]] && target_ws=1

# 4. Open the scratchpad terminal attached to the new session.
log "launching foot for session $sid (target ws=$target_ws)"
setsid foot --app-id=aoe-cwd "$attach_script" >>"$LOG" 2>&1 &

# 5. Wait for the window to map, then move it onto the current workspace and
#    focus it (overriding the "workspace = 99 silent" window rule).
addr=""
for _ in $(seq 1 50); do
    addr=$(hyprctl clients -j 2>/dev/null \
        | jq -r '.[] | select(.class=="aoe-cwd") | .address' | head -1)
    [[ -n "$addr" && "$addr" != "null" ]] && break
    sleep 0.1
done

if [[ -n "$addr" && "$addr" != "null" ]]; then
    hyprctl dispatch movetoworkspace "$target_ws,address:$addr" 2>/dev/null
    hyprctl dispatch focuswindow "address:$addr" 2>/dev/null
    log "revealed window $addr on ws $target_ws"
else
    log "WARN: aoe-cwd window did not appear within timeout"
    notify-send -u critical "AOE Scratchpad" "Window did not open for '$session_title'"
fi
