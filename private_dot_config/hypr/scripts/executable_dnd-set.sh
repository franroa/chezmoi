#!/usr/bin/env bash
# Deterministically set hyprpanel Do Not Disturb on/off.
#
# `hyprpanel dnd` is a *toggle* only (toggleDnd -> set_dont_disturb(!dnd)), so
# lock/unlock relying on paired toggles desyncs whenever anything else touches
# DND (MeetingDetector.sh, DndMode.sh, manual toggle, sleep double-lock) and
# unlock can leave notifications silenced. This reads the persisted state and
# toggles only when it differs from the requested state, so the result is
# idempotent: `dnd-set.sh off` always ends with DND off.
#
# Usage: dnd-set.sh on|off
set -euo pipefail

STATE_FILE="$HOME/.local/state/astal/notifd/notifications.json"
HYPRPANEL="$HOME/.local/bin/hyprpanel"

# `hyprpanel` forwards to the astal IPC socket under XDG_RUNTIME_DIR. When invoked
# from a sparse env (e.g. hypridle's unlock/lock hooks) that var can be missing,
# which makes the toggle silently no-op. Provide the standard fallback.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

desired="${1:-}"
case "$desired" in
  on|off) ;;
  *) echo "usage: $0 on|off" >&2; exit 2 ;;
esac

# Current DND from the astal-notifd persisted state (updated live on change).
current_dnd() {
  python3 - "$STATE_FILE" <<'PY' 2>/dev/null || echo off
import json, sys
try:
    print("on" if json.load(open(sys.argv[1])).get("dont_disturb") else "off")
except Exception:
    print("off")
PY
}

if [ "$(current_dnd)" != "$desired" ]; then
  "$HYPRPANEL" dnd >/dev/null 2>&1 || true
fi
