#!/usr/bin/env bash
# Staged-pipeline baton: a single shared file that drives one Claude through
# plan -> implement -> test -> review -> done, while monitor panes react to it.
# The working Claude advances the baton (`set`); a watcher pane parks on a
# stage (`on`) and fires a command when the baton reaches it, then auto-advances.
#
#   pipeline-baton.sh init  <id>                 create baton at stage "plan"
#   pipeline-baton.sh set   <id> <stage>         move baton to <stage>
#   pipeline-baton.sh show  <id>                 render the stage strip
#   pipeline-baton.sh get   <id>                 print the current stage word
#   pipeline-baton.sh on    <stage> <id> -- cmd  wait for <stage>, run cmd, advance
#
# Baton dir: /tmp/aoe-pipeline-<id>/  (stage + stage.log)
set -uo pipefail

STAGES=(plan implement test review done)
base() { echo "/tmp/aoe-pipeline-$1"; }

next_after() {
  local cur="$1" i
  for i in "${!STAGES[@]}"; do
    if [ "${STAGES[$i]}" = "$cur" ]; then
      echo "${STAGES[$((i+1))]:-done}"; return
    fi
  done
  echo done
}

bset() {  # id stage
  local d; d="$(base "$1")"; mkdir -p "$d"
  printf '%s\n' "$2" > "$d/stage"
  printf '%s\t%s\n' "$2" "$(date +%s)" >> "$d/stage.log"
}

show() {  # id
  local d cur; d="$(base "$1")"
  [ -f "$d/stage" ] || { echo "(no pipeline $1)"; return; }
  cur="$(cat "$d/stage")"
  local s out=""
  for s in "${STAGES[@]}"; do
    if [ "$s" = "$cur" ]; then out+="$(printf '\033[1;38;2;137;220;235m[%s]\033[0m' "$s")"
    else                       out+="$(printf '\033[2m %s \033[0m' "$s")"; fi
    [ "$s" = done ] || out+="$(printf '\033[2m→\033[0m')"
  done
  printf '%s\n' "$out"
}

on() {  # stage id -- cmd...
  local want="$1" id="$2"; shift 2
  [ "${1:-}" = "--" ] && shift
  local d; d="$(base "$id")"
  echo "parked: waiting for stage '$want' on pipeline '$id'…"
  while :; do
    [ -f "$d/stage" ] && [ "$(cat "$d/stage")" = "$want" ] && break
    sleep 1
  done
  echo "stage '$want' reached — running: $*"
  if "$@"; then
    bset "$id" "$(next_after "$want")"
    echo "✓ advanced to $(cat "$d/stage")"
  else
    echo "✗ command failed; baton left at '$want'" >&2
    return 1
  fi
}

case "${1:-}" in
  init) bset "${2:?id}" plan; echo "pipeline ${2} -> plan" ;;
  set)  bset "${2:?id}" "${3:?stage}" ;;
  get)  cat "$(base "${2:?id}")/stage" 2>/dev/null ;;
  show) show "${2:?id}" ;;
  on)   shift; on "$@" ;;
  *) echo "usage: pipeline-baton.sh {init <id>|set <id> <stage>|get <id>|show <id>|on <stage> <id> -- <cmd>}" >&2; exit 1 ;;
esac
