#!/usr/bin/env bash
# Dynamic-workflow primitives: the verbs an orchestrator-Claude (or a human)
# calls to spawn, drive, observe, and reap AOE worker sessions at runtime.
# Worker state is the same Claude status file the dashboard reads.
#
#   orchestrate.sh spawn <name> [--base <ref>] ["seed prompt"]   -> prints worker id
#   orchestrate.sh send  <id> "<message>"
#   orchestrate.sh wait  <id> [done|input]        block until worker reaches state
#   orchestrate.sh collect <id> [-n N]            print last N lines of the pane
#   orchestrate.sh state                          table of this workflow's workers
#   orchestrate.sh reap  <id>                     remove worker (worktree+branch)
#   orchestrate.sh reap-all                       remove every worker in the registry
#
# Workflow id comes from $WF (default "wf"). Registry: /tmp/aoe-workflow-<WF>/registry
#   lines: <aoe_id>\t<tmux_session>\t<name>
set -uo pipefail

AOE="$(command -v aoe || echo /home/linuxbrew/.linuxbrew/bin/aoe)"
WF="${WF:-wf}"
REG_DIR="/tmp/aoe-workflow-${WF}"
REG="$REG_DIR/registry"

for bin in aoe jq tmux; do
  command -v "$bin" >/dev/null 2>&1 || { echo "❌ missing dependency: $bin" >&2; exit 1; }
done

aoe_sessions() { tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^aoe_' || true; }
reg_tmux() { grep -P "^$1\t" "$REG" 2>/dev/null | head -1 | cut -f2; }

session_state() {  # tmux_session -> working|input|done|idle
  local f="/tmp/.claude-tmux-status-${1}" raw ts
  [ -f "$f" ] || { echo idle; return; }
  raw="$(cat "$f" 2>/dev/null)"
  case "$raw" in
    input) echo input ;;
    done)  echo done ;;
    working:*) ts="${raw#working:}"; [ $(( $(date +%s) - ts )) -lt 300 ] && echo working || echo idle ;;
    *) echo idle ;;
  esac
}

spawn() {
  local name="" base="" seed=""
  name="${1:?worker name}"; shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --base) base="${2:-}"; shift 2 ;;
      *) seed="$1"; shift ;;
    esac
  done
  mkdir -p "$REG_DIR"; touch "$REG"
  local before after new id add=( . -w "$name" -b -t "$name" -l )
  [ -n "$base" ] && add+=( --base-branch "$base" )
  before="$(aoe_sessions)"
  if ! "$AOE" add "${add[@]}" >/dev/null 2>&1; then
    echo "orchestrate: aoe add failed for '$name'" >&2; return 1
  fi
  id="$("$AOE" list --json 2>/dev/null | jq -r 'sort_by(.created_at)|last|.id')"
  new=""
  for _ in $(seq 1 20); do
    after="$(aoe_sessions)"
    new="$(comm -13 <(printf '%s\n' "$before" | sort -u) <(printf '%s\n' "$after" | sort -u) \
           | grep '^aoe_' | head -1)"
    [ -n "$new" ] && break
    sleep 0.5
  done
  printf '%s\t%s\t%s\n' "${id:-?}" "${new:-?}" "$name" >> "$REG"
  [ -n "$seed" ] && [ -n "$id" ] && "$AOE" send "$id" "$seed" >/dev/null 2>&1 || true
  echo "spawned worker '$name' id=${id} tmux=${new} (wf=$WF)" >&2
  printf '%s\n' "$id"   # stdout = id only, for capture
}

wait_for() {  # id [state]
  local id="${1:?id}" want="${2:-done}" tmux
  tmux="$(reg_tmux "$id")"
  [ -z "$tmux" ] || [ "$tmux" = "?" ] && { echo "orchestrate: no tmux session for $id" >&2; return 1; }
  echo "waiting for $id ($tmux) to reach '$want'…" >&2
  while [ "$(session_state "$tmux")" != "$want" ]; do sleep 2; done
  echo "$id reached '$want'" >&2
}

state() {
  [ -f "$REG" ] || { echo "(empty workflow $WF)"; return 0; }
  printf '%-18s %-28s %-16s %s\n' ID TMUX NAME STATE
  local id tmux name
  while IFS=$'\t' read -r id tmux name; do
    [ -z "${id:-}" ] && continue
    printf '%-18s %-28s %-16s %s\n' "$id" "$tmux" "$name" "$(session_state "$tmux")"
  done < "$REG"
}

reap() {  # id
  local id="${1:?id}"
  "$AOE" remove "$id" --delete-worktree --delete-branch --force >/dev/null 2>&1 \
    || echo "warn: aoe remove failed for $id" >&2
  [ -f "$REG" ] && { grep -vP "^$id\t" "$REG" > "$REG.tmp" 2>/dev/null || true; mv -f "$REG.tmp" "$REG"; }
  echo "reaped $id" >&2
}

reap_all() {
  [ -f "$REG" ] || { echo "(nothing to reap)"; return 0; }
  local id _t _n
  while IFS=$'\t' read -r id _t _n; do [ -n "${id:-}" ] && [ "$id" != "?" ] && reap "$id"; done < "$REG"
  rm -f "$REG"
}

case "${1:-}" in
  spawn)    shift; spawn "$@" ;;
  send)     shift; "$AOE" send "${1:?id}" "${2:?msg}" ;;
  wait)     shift; wait_for "$@" ;;
  collect)  shift; "$AOE" session capture "${1:?id}" -n "${3:-50}" --strip-ansi ;;
  state)    state ;;
  reap)     shift; reap "${1:?id}" ;;
  reap-all) reap_all ;;
  *) echo "usage: orchestrate.sh {spawn|send|wait|collect|state|reap|reap-all} … (WF=<id>)" >&2; exit 1 ;;
esac
