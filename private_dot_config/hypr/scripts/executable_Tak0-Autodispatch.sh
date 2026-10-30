#!/usr/bin/env bash
source "$HOME/.config/hypr/scripts/hypr-lua.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Tak0-Autodispatch.sh
# ─────────────────────────────────────────────────────────────────────────────
# This script is an "authoritative spawn dispatcher" for Hyprland.
#
# Its purpose is to FORCE all windows belonging to a single application launch
# (main window + helpers + Electron / Steam child processes)
# onto a specific workspace.
#
# It explicitly ignores:
#   • spawn race conditions
#   • delayed window creation
#   • detached helper processes
#   • Electron / Chromium / Steam madness
#
# Typical use cases:
#   • Launch Steam / Discord / browsers without window leakage
#   • Prevent apps from spawning on the currently focused workspace
#   • Control applications that completely ignore static windowrules
#
# Invocation:
#   ./Tak0-Autodispatch.sh <workspace> [rule ...] -- <command>
#
# Important notes:
#   • All window rules are TEMPORARY
#   • No permanent pollution of Hyprland configuration
# ─────────────────────────────────────────────────────────────────────────────
# REQUIREMENTS:
#   - hyprctl   → runtime control of Hyprland
#   - jq        → JSON client parsing
#   - pgrep/ps  → process tree inspection

set -u

LOGFILE="$(dirname "$0")/dispatch.log"

# ─────────────────────────────────────────────────────────────────────────────
# Temporary rules (Lua config: windowrulev2 keywords are gone)
# ─────────────────────────────────────────────────────────────────────────────
#   Rules are created through `hyprctl eval` and kept in a Lua table keyed by
#   this script's PID so they can be switched off again (rule handles).

# tak0_rule_add <kind: wide|cap> <field> <regex>   (field: class, title, initial_class, ...)
tak0_rule_add() {
  hyprctl eval "tak0_rules = tak0_rules or {}; tak0_rules[\"$$-$1\"] = tak0_rules[\"$$-$1\"] or {}; table.insert(tak0_rules[\"$$-$1\"], hl.window_rule({ match = { $2 = $(hl_str "$3") }, workspace = $(hl_str "$TARGET_WS silent") }))"
}

# tak0_rule_clear <kind>
tak0_rule_clear() {
  hyprctl eval "for _, r in ipairs((tak0_rules or {})[\"$$-$1\"] or {}) do r:set_enabled(false) end; if tak0_rules then tak0_rules[\"$$-$1\"] = nil end"
}

# Old windowrulev2 style "field:regex" -> Lua match field + regex
tak0_rule_split() {
  local field="${1%%:*}" regex="${1#*:}"
  case "$field" in
    initialClass) field=initial_class ;;
    initialTitle) field=initial_title ;;
  esac
  printf '%s %s' "$field" "$regex"
}

# ─────────────────────────────────────────────────────────────────────────────
# 0️⃣ ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────
#   $1            → target workspace
#   Next args     → optional capture rules (windowrulev2 syntax)
#   "--"          → argument separator
#   After "--"    → command to execute (verbatim)

TARGET_WS="$1"
shift || true

CAPTURE_RULES=()
while [[ "${1-}" != "--" && -n "${1-}" ]]; do
  CAPTURE_RULES+=("$1")
  shift || break
done

if [[ "${1-}" == "--" ]]; then
  shift
fi

CMD="$*"

if [[ -z "$TARGET_WS" || -z "$CMD" ]]; then
  echo "Usage: $0 <workspace> [rule rule ...] -- <command>" >>"$LOGFILE"
  exit 1
fi

echo "=== Deploy '$CMD' → WS $TARGET_WS @ $(date) ===" >>"$LOGFILE"

# ─────────────────────────────────────────────────────────────────────────────
# 1️⃣ HYPRLAND READINESS GATE
# ─────────────────────────────────────────────────────────────────────────────
#   Hyprland may not be fully initialized during early autostart.
#   hyprctl silently fails if called too early.

for _ in {1..50}; do
  hyprctl -j monitors >/dev/null 2>&1 && break
  sleep 0.1
done

# ─────────────────────────────────────────────────────────────────────────────
# 2️⃣ CLEANUP GUARANTEE
# ─────────────────────────────────────────────────────────────────────────────
#   Ensures that ALL temporary rules are removed
#   even on crash, SIGTERM, or user interruption.

cleanup() {
  echo "Cleanup: removing temporary capture rules and initialWorkspace at $(date)" >>"$LOGFILE"

  tak0_rule_clear wide >>"$LOGFILE" 2>&1 || true
  tak0_rule_clear cap >>"$LOGFILE" 2>&1 || true
}

trap cleanup EXIT INT TERM ERR

# ─────────────────────────────────────────────────────────────────────────────
# 3️⃣ ULTRA-EARLY GLOBAL CAPTURE (NUCLEAR OPTION)
# ─────────────────────────────────────────────────────────────────────────────
#   Temporarily forces ALL windows (initialClass:.*)
#   onto the target workspace.
#
#   Protects against ultra-fast helpers:
#     • gpu-process
#     • renderer
#     • steamwebhelper

echo "Applying temporary initialWorkspace capture (initialClass:.*)" >>"$LOGFILE"
tak0_rule_add wide initial_class ".*" >>"$LOGFILE" 2>&1 || true

# ─────────────────────────────────────────────────────────────────────────────
# 3️⃣.1 OPTIONAL CLASS-BASED PRE-CAPTURE
# ─────────────────────────────────────────────────────────────────────────────
#   Additional precision rules.
#   Useful for Electron / Steam multi-process hell.

for RULE in "${CAPTURE_RULES[@]}"; do
  echo "Applying temporary capture rule: $RULE" >>"$LOGFILE"
  # shellcheck disable=SC2046
  tak0_rule_add cap $(tak0_rule_split "$RULE") >>"$LOGFILE" 2>&1 || true
done

# ─────────────────────────────────────────────────────────────────────────────
# 4️⃣ APPLICATION LAUNCH
# ─────────────────────────────────────────────────────────────────────────────
#   bash -c allows aliases, env vars, wrappers.
#   ROOT_PID is the root of process lineage.

bash -c "$CMD" &
ROOT_PID=$!
echo "Root PID: $ROOT_PID" >>"$LOGFILE"

# Resolve canonical process name
APP_NAME=""
for _ in {1..20}; do
  if [[ -r "/proc/$ROOT_PID/comm" ]]; then
    APP_NAME="$(tr -d '\0' </proc/$ROOT_PID/comm 2>/dev/null || true)"
    break
  fi
  sleep 0.05
done

if [[ -z "$APP_NAME" ]]; then
  read -r -a __toks <<<"$CMD"
  APP_NAME="$(basename "${__toks[0]}")"
fi

echo "App gate name: $APP_NAME" >>"$LOGFILE"

sleep 1.5

#!TO-DO: Release the nuclear option ASAP
echo "Releasing ultra-early wide capture" >>"$LOGFILE"
tak0_rule_clear wide >>"$LOGFILE" 2>&1 || true

# ─────────────────────────────────────────────────────────────────────────────
# 5️⃣ SUPERVISION LOOP (AUTHORITATIVE PHASE)
# ─────────────────────────────────────────────────────────────────────────────
#   This loop:
#     • scans ALL Hyprland clients
#     • matches PID lineage
#     • matches detached helpers
#     • matches class rules

get_descendants() {
  local root="$1"
  local all=("$root")
  local changed=1

  while ((changed)); do
    changed=0
    for p in "${all[@]}"; do
      for c in $(pgrep -P "$p" 2>/dev/null || true); do
        if [[ ! " ${all[*]} " =~ " $c " ]]; then
          all+=("$c")
          changed=1
        fi
      done
    done
  done

  echo "${all[@]}"
}

pid_matches_app() {
  local pid="$1"
  local comm
  comm="$(ps -p "$pid" -o comm= 2>/dev/null)" || return 1
  [[ "$comm" == "$APP_NAME" || "$comm" == "$APP_NAME"* ]]
}

END_TIME=$((SECONDS + 20))
declare -A SEEN

while ((SECONDS < END_TIME)); do
  PIDS="$(get_descendants "$ROOT_PID")"

  while IFS=$'\t' read -r PID ADDR CLASS; do
    MATCH=0

    for TPID in $PIDS; do
      [[ "$PID" == "$TPID" ]] && MATCH=1 && break
    done

    pid_matches_app "$PID" && MATCH=1

    for RULE in "${CAPTURE_RULES[@]}"; do
      if [[ "$RULE" =~ class:\^\((.*)\)\$ ]]; then
        [[ "$CLASS" =~ ${BASH_REMATCH[1]} ]] && MATCH=1
      fi
    done

    if ((MATCH)) && [[ -z "${SEEN[$ADDR]-}" ]]; then
      echo "Placing window $ADDR (pid $PID, class $CLASS) → WS $TARGET_WS" >>"$LOGFILE"
      hl_move_window_silent "$TARGET_WS" "address:$ADDR" >>"$LOGFILE" 2>&1 || true
      SEEN[$ADDR]=1
    fi
  done < <(hyprctl clients -j | jq -r '.[] | [.pid, .address, .class] | @tsv')

  sleep 0.01
done

echo "=== Deploy finished: '$CMD' ===" >>"$LOGFILE"
exit 0
