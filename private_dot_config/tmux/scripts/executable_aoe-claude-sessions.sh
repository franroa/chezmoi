#!/usr/bin/env bash
# Pick any Claude Code session across ALL repositories and open it in a fresh
# tmux session running `claude --resume <id>` in that repo, then switch the
# parent client into it (the same start-then-switch-client flow used for
# parallel work).
#
# Source of truth is Claude Code's own session store, not aoe: every transcript
# under ~/.claude/projects/<encoded-repo>/<session-id>.jsonl is one resumable
# session.  The repo path is read from each transcript's `cwd` (the encoded dir
# name is lossy because real repo names contain dashes too).
#
#   aoe-claude-sessions.sh              fzf picker (default); enter = resume it
#   aoe-claude-sessions.sh --list       print rows: id\trepo\tmtime\tlabel
#   aoe-claude-sessions.sh --enter ID   resume ID in a new tmux session + switch
#   aoe-claude-sessions.sh --preview ID transcript summary for the fzf preview
set -uo pipefail

PROJECTS="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

for bin in jq tmux; do
  command -v "$bin" >/dev/null 2>&1 || { echo "❌ missing dependency: $bin" >&2; exit 1; }
done
CLAUDE="$(command -v claude || echo claude)"

# Locate a transcript file by its session id (filename stem).
find_file() { find "$PROJECTS" -maxdepth 2 -name "${1}.jsonl" -print -quit 2>/dev/null; }

# repo cwd recorded inside a transcript (first line that carries .cwd).
file_cwd() { grep -m1 -o '"cwd":"[^"]*"' "$1" 2>/dev/null | head -1 | sed 's/^"cwd":"//; s/"$//'; }

# The Claude Code session name: the user-set custom title, else the AI-generated
# title (the name shown in `claude --resume`).  Titles can be rewritten during a
# session, so take the latest one.  Falls back to the first real user prompt.
file_label() {
  local f="$1" s
  s="$(grep '"type":"custom-title"' "$f" 2>/dev/null | tail -1 | jq -r '.customTitle // empty' 2>/dev/null)"
  [ -z "$s" ] && s="$(grep '"type":"ai-title"' "$f" 2>/dev/null | tail -1 | jq -r '.aiTitle // empty' 2>/dev/null)"
  if [ -z "$s" ]; then
    # No title yet: first real user prompt, skipping slash-command / caveat wrappers.
    s="$(grep -m8 '"type":"user"' "$f" 2>/dev/null | jq -rs '
      [ .[] | (.message.content) as $c
        | if   ($c|type)=="string" then $c
          elif ($c|type)=="array"  then ([$c[]|select(.type=="text")|.text]|join(" "))
          else "" end ]
      | map(select(. != "" and (startswith("<")|not) and (startswith("Caveat")|not)))
      | .[0] // ""' 2>/dev/null)"
  fi
  printf '%s' "$s" | tr '\n\t' '  ' | sed -E 's/  +/ /g' | cut -c1-70
}

# id \t repo-basename \t YYYY-MM-DD HH:MM \t label   — newest first.
list() {
  [ -d "$PROJECTS" ] || { echo "no Claude store at $PROJECTS" >&2; return 0; }
  local f id cwd repo mtime label
  # sort files by mtime, newest first
  while IFS= read -r f; do
    [ -s "$f" ] || continue
    id="$(basename "$f" .jsonl)"
    cwd="$(file_cwd "$f")"; [ -z "$cwd" ] && cwd="?"
    repo="$(basename "$cwd")"
    mtime="$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null)"
    label="$(file_label "$f")"
    printf '%s\t%s\t%s\t%s\n' "$id" "$repo" "$mtime" "$label"
  done < <(find "$PROJECTS" -maxdepth 2 -name '*.jsonl' -printf '%T@\t%p\n' 2>/dev/null \
            | sort -rn | cut -f2-)
}

preview() {
  local id="$1" f cwd
  f="$(find_file "$id")" || true
  [ -z "${f:-}" ] && { echo "session $id not found"; return 0; }
  cwd="$(file_cwd "$f")"
  printf 'name : %s\n' "$(file_label "$f")"
  printf 'repo : %s\n' "${cwd:-?}"
  printf 'id   : %s\n' "$id"
  printf 'file : %s\n\n' "$f"
  # last few human/assistant text turns
  grep -E '"type":"(user|assistant)"' "$f" 2>/dev/null | tail -8 | jq -r '
    (.type) as $t | (.message.content) as $c
    | (if   ($c|type)=="string" then $c
       elif ($c|type)=="array"  then ([$c[]|select(.type=="text")|.text]|join(" "))
       else "" end) as $txt
    | select($txt != "")
    | "[\($t)] \($txt[0:200])"' 2>/dev/null
}

# Open the chosen session in a new tmux session (claude --resume) and switch to it.
enter() {
  local id="${1:-}" want="${2:-}" f cwd name
  [ -z "$id" ] && exit 0
  f="$(find_file "$id")" || true
  if [ -z "${f:-}" ]; then echo "session $id not found" >&2; sleep 1.5; exit 1; fi

  cwd="$(file_cwd "$f")"
  if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
    echo "repo dir gone for $id (cwd=${cwd:-?}); resuming from \$HOME" >&2
    cwd="$HOME"; sleep 1
  fi

  # Session name. With $want (the session's own title, via --enter-titled) use a
  # tmux-safe slug of it; else the stable cc-<repo>-<id8>. tmux targets treat
  # '.' and ':' specially, so strip them; collapse spaces; cap length.
  if [ -n "$want" ]; then
    name="$(printf '%s' "$want" | tr '.:' '  ' | tr -s ' ' ' ' \
            | sed -E 's/^ +//; s/ +$//' | cut -c1-50)"
  fi
  if [ -z "${name:-}" ]; then
    name="cc-$(basename "$cwd" | tr -c 'A-Za-z0-9_-' '-')-${id:0:8}"
    name="$(printf '%s' "$name" | sed -E 's/-+/-/g; s/-$//')"
  fi

  if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$cwd" "$CLAUDE --resume $id"
  fi

  if [ -n "${TMUX_PARENT_CLIENT:-}" ]; then
    tmux switch-client -c "$TMUX_PARENT_CLIENT" -t "$name"
  elif [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach -t "$name"
  fi
}

case "${1:-}" in
  --list)    list ;;
  --enter)   shift; enter "${1:-}" ;;
  --enter-titled)  # name the new tmux session after the session's own title
             shift; enter "${1:-}" "$(file_label "$(find_file "${1:-}")")" ;;
  --preview) shift; preview "${1:-}" ;;
  *)
    rows="$(list)"
    [ -z "$rows" ] && { echo "no Claude Code sessions found under $PROJECTS"; sleep 1.2; exit 0; }
    sel="$(printf '%s\n' "$rows" | fzf \
      --reverse --height=100% \
      --delimiter='\t' --with-nth=2,3,4 \
      --prompt='claude session: ' \
      --header=' enter:resume in new tmux session · all repos · repo · when · name' \
      --preview="$0 --preview {1}" \
      --preview-window=down:45%:wrap)"
    [ -z "$sel" ] && exit 0
    enter "$(printf '%s' "$sel" | cut -f1)"
    ;;
esac
