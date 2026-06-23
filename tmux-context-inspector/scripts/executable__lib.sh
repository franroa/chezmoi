#!/usr/bin/env bash
#
# _lib.sh — shared primitives: locate the Claude pane, map its cwd to the
# session transcript, token formatting, popup, and a loose parser.
#
# Sourced by _capture.sh (and, transitively, by every show_*.sh).

set -u

# --- Configuration (override via set-environment -g in tmux.conf) ------------
CI_POPUP_WIDTH="${CI_POPUP_WIDTH:-120}"
CI_POPUP_HEIGHT="${CI_POPUP_HEIGHT:-35}"
CI_CACHE_TTL="${CI_CACHE_TTL:-5}"               # seconds the cached report lives
CI_CACHE_FILE="${TMPDIR:-/tmp}/ci_context_cache.txt"
CI_PROJECTS_DIR="${CI_PROJECTS_DIR:-$HOME/.claude/projects}"
# Context window if it can't be inferred from the model. Explicit override wins.
CI_CONTEXT_WINDOW="${CI_CONTEXT_WINDOW:-}"
# Viewer for the single-view popups: nvim (default, vi navigation) | less.
# Falls back to less if nvim isn't installed.
CI_PAGER="${CI_PAGER:-nvim}"
# Dir of this lib (= scripts/), used to locate pager.vim.
CI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# --- tmux version -----------------------------------------------------------
ci_tmux_version_ge() {
    local want="$1" have
    have="$(tmux -V | sed 's/[^0-9.]//g')"
    [ -z "$have" ] && return 1
    [ "$(printf '%s\n%s\n' "$want" "$have" | sort -V | head -n1)" = "$want" ]
}

# --- Locate the pane running Claude Code ------------------------------------
ci_find_claude_pane() {
    local pane
    pane="$(tmux list-panes -F '#{pane_id} #{pane_current_command}' \
        | awk 'tolower($2) ~ /claude/ {print $1; exit}')"
    [ -n "$pane" ] && { echo "$pane"; return 0; }

    pane="$(tmux list-panes -F '#{pane_id} #{pane_current_command}' \
        | awk 'tolower($2) ~ /node/ {print $1; exit}')"
    [ -n "$pane" ] && { echo "$pane"; return 0; }

    pane="$(tmux list-panes -s -F '#{pane_id} #{pane_current_command}' \
        | awk 'tolower($2) ~ /claude|node/ {print $1; exit}')"
    echo "$pane"
}

# Working directory of the pane (approximate project root).
ci_project_dir() {
    local pane="$1"
    [ -n "$pane" ] && tmux display-message -p -t "$pane" '#{pane_current_path}'
}

# cwd -> Claude Code project-dir slug (/ and . -> -).
ci_slug_for_dir() {
    printf '%s' "$1" | sed 's/[/.]/-/g'
}

# Active transcript (most recent JSONL) for the given cwd. Empty if none.
ci_transcript_for_dir() {
    local dir="$1" slug proj
    [ -n "$dir" ] || return 1
    slug="$(ci_slug_for_dir "$dir")"
    proj="$CI_PROJECTS_DIR/$slug"
    [ -d "$proj" ] || return 1
    ls -t "$proj"/*.jsonl 2>/dev/null | head -n1
}

# --- agentsview (session analytics over the same JSONL) ---------------------
# agentsview parses ~/.claude/projects/*.jsonl into SQLite and exposes fast,
# maintained subcommands. The o/i/c views lean on it; if it isn't installed,
# o/i fall back to their old jq scrape.
ci_have_agentsview() { command -v agentsview >/dev/null 2>&1; }

# Transcript path -> agentsview session id (= UUID from the filename).
ci_session_id() { local t="${1:-}"; [ -n "$t" ] && basename "$t" .jsonl; }

# Refresh the LIVE session in the DB before querying (parse a single session,
# cheap). Silent; doesn't fail the view if agentsview/transcript are missing.
ci_sync_session() {
    local t="${1:-}"
    ci_have_agentsview && [ -n "$t" ] && [ -f "$t" ] \
        && agentsview session sync "$t" >/dev/null 2>&1
    return 0
}

# --- Tokens / window --------------------------------------------------------
# Format an integer to 1.2k / 1.2m.
ci_fmt_tokens() {
    awk -v n="$1" 'BEGIN{
        if (n+0 >= 1000000) printf "%.1fm", n/1000000;
        else if (n+0 >= 1000) printf "%.1fk", n/1000;
        else printf "%d", n;
    }'
}

# Context window for a model (heuristic + env override).
ci_window_for_model() {
    local model="$1" total="${2:-0}" win="$CI_CONTEXT_WINDOW"
    if [ -z "$win" ]; then
        case "$model" in
            *opus-4-8*) win=1000000 ;;   # 1M beta (confirmed in /context)
            *)          win=200000  ;;
        esac
    fi
    # If usage already exceeds the assumed window, bump to the next tier.
    [ "${total:-0}" -gt "$win" ] && win=1000000
    echo "$win"
}

# --- Section parser (loose match) -------------------------------------------
ci_section() {
    local file="$1" key="$2"
    if ! grep -i -- "$key" "$file" 2>/dev/null; then
        printf '(not found: "%s")\n' "$key"
    fi
}

# --- Color ------------------------------------------------------------------
# Colorize plain text (stdin -> stdout) with SGR; less -R paints it. Rules per
# line type + inline highlights. Leave alone if the input already carries ANSI.
ci_colorize() {
    local E
    E=$(printf '\033')
    sed -E \
        -e "s/^(═══.*═══)[[:space:]]*$/${E}[1;36m\1${E}[0m/" \
        -e "s/^(Context Usage.*)$/${E}[1;35m\1${E}[0m/" \
        -e "s/^(Model:.*)$/${E}[36m\1${E}[0m/" \
        -e "s/^(Tokens:.*)$/${E}[1;33m\1${E}[0m/" \
        -e "s/^(Free space:.*)$/${E}[1;32m\1${E}[0m/" \
        -e "s/^(Usage:.*)$/${E}[1;33m\1${E}[0m/" \
        -e "s/^(Breakdown.*|On-disk inventory:|System prompt \/.*)$/${E}[1;34m\1${E}[0m/" \
        -e "s/^([[:space:]]*—[[:space:]].*)$/${E}[33m\1${E}[0m/" \
        -e "s/(requiere \/context[^$]*|Para [^$]*|Abre la vista[^$]*|usa la vista[^$]*)/${E}[2m\1${E}[0m/" \
        -e "s/•/${E}[36m•${E}[0m/g" \
        -e "s#(^|[[:space:]])/(context|mcp|memory|cost|compact|permissions|agents|skills)\b#\1${E}[35m/\2${E}[0m#g"
}

# --- Popup ------------------------------------------------------------------
ci_popup_file() {
    local file="$1" render cmd esc
    esc="$(printf '\033')"

    if [ "$CI_PAGER" = nvim ] && command -v nvim >/dev/null 2>&1; then
        # nvim does NOT paint SGR in a normal buffer: strip the ANSI (whether it
        # came from ci_colorize or the live /context) and let pager.vim recolor
        # by pattern (same rules as ci_colorize) in a read-only buffer with vi
        # navigation. CI_PAGER=less reverts to less -R.
        render="$(mktemp)"
        # Strip SGR (color) sequences — the only ANSI the reports and the live
        # /context carry. Delimiter # so nothing in the pattern clashes.
        sed -r "s#${esc}\[[0-9;]*m##g" "$file" > "$render"
        cmd="nvim -RNn -u NONE -c 'source $CI_LIB_DIR/pager.vim' -- '$render'"
    else
        # less: plain text -> colorize it; the live /context already has ANSI, intact.
        render="$file"
        if ! grep -q "$esc" "$file" 2>/dev/null; then
            render="$(mktemp)"
            ci_colorize < "$file" > "$render"
        fi
        cmd="less -R -- '$render'"
    fi

    if ci_tmux_version_ge 3.2; then
        tmux display-popup -E -w "$CI_POPUP_WIDTH" -h "$CI_POPUP_HEIGHT" "$cmd"
    else
        tmux split-window "$cmd"
    fi
}

ci_popup_text() {
    local tmp
    tmp="$(mktemp)"
    printf '%s\n' "$1" > "$tmp"
    ci_popup_file "$tmp"
}
