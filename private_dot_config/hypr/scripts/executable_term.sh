#!/usr/bin/env bash
# Terminal launcher for $term in lua/vars.lua (SUPER+Return, Dropterminal, waybar helpers).
# Diagnostics for "terminals do not open in Hyprland": every launch and ghostty's own stderr go to
# ~/.cache/hypr-terminal.log, and if ghostty dies within 3s a fallback terminal is started instead.
# Remove (point `term` back at ~/.local/bin/ghostty) once the cause is understood.

LOG="$HOME/.cache/hypr-terminal.log"
mkdir -p "$(dirname "$LOG")"
[[ -f "$LOG" && $(stat -c %s "$LOG") -gt 1048576 ]] && : >"$LOG"   # keep it small

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }

log "launch args=[$*] WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-} DISPLAY=${DISPLAY:-} XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-} XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-} HYPR_SIG=${HYPRLAND_INSTANCE_SIGNATURE:+set} GSK_RENDERER=${GSK_RENDERER:-} GDK_BACKEND=${GDK_BACKEND:-}"

start=$SECONDS
"$HOME/.local/bin/ghostty" "$@" >>"$LOG" 2>&1
rc=$?
log "ghostty exited rc=$rc after $((SECONDS - start))s"

if ((rc != 0 && SECONDS - start < 3)); then
    for t in foot kitty; do
        if command -v "$t" >/dev/null 2>&1; then
            log "ghostty failed fast, falling back to $t"
            exec "$t"
        fi
    done
fi
exit "$rc"
