#!/usr/bin/env bash
#
# _capture.sh — reporte de contexto SIN enviar /context al REPL.
#
# Lee el transcript de sesión (JSONL) que Claude Code escribe en disco y calcula
# el llenado real de la ventana de contexto (input + cache_creation + cache_read
# del último mensaje con uso). Enriquecido con un inventario de disco. El reporte
# se cachea CI_CACHE_TTL segundos. Cada vista parsea este reporte.
#
# La vieja vía de scrapear el REPL queda como `ci_capture_live` (opt-in), para
# el desglose oficial por categoría que sólo /context puede dar.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

# Campos de uso del último mensaje del transcript:
#   "<model> <total> <input> <cache_creation> <cache_read> <msgcount>"
# Devuelve 1 si no hay datos de uso.
ci_usage_fields() {
    local t="$1"
    [ -n "$t" ] && [ -f "$t" ] || return 1
    jq -rs '
        ([ .[] | select(.message.usage != null) ] | last) as $e
        | if $e == null then empty else
            ($e.message.usage) as $u
            | [ ($e.message.model // "unknown"),
                (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)),
                ($u.input_tokens // 0),
                ($u.cache_creation_input_tokens // 0),
                ($u.cache_read_input_tokens // 0),
                ([ .[] | select(.type=="user" or .type=="assistant") ] | length)
              ] | @tsv
          end
    ' "$t" 2>/dev/null | tr '\t' ' '
}

# Cuenta archivos y suma bytes (~tokens = bytes/4) de un glob. Imprime "N ~Kfmt".
_ci_count_tokens() {
    local n=0 bytes=0 f
    for f in "$@"; do
        [ -e "$f" ] || continue
        n=$((n + 1))
        bytes=$((bytes + $(wc -c < "$f" 2>/dev/null || echo 0)))
    done
    printf '%s ~%s' "$n" "$(ci_fmt_tokens $((bytes / 4)))"
}

# Inventario de disco para el cwd dado.
_ci_disk_inventory() {
    local dir="$1"
    local agents memory skills mcp

    agents="$(_ci_count_tokens "$HOME"/.claude/agents/*.md "$dir"/.claude/agents/*.md)"
    memory="$(_ci_count_tokens "$HOME"/.claude/CLAUDE.md "$HOME"/.claude/rules/common/*.md \
              "$dir"/CLAUDE.md "$dir"/.claude/CLAUDE.md)"
    # Skills: dirs con SKILL.md bajo skills/ (proyecto + usuario).
    local sk=0
    for d in "$HOME"/.claude/skills/*/ "$dir"/.claude/skills/*/; do
        [ -d "$d" ] && sk=$((sk + 1))
    done
    skills="$sk dirs"
    # MCP servers: claves mcpServers en configs presentes.
    mcp="$(jq -r '[.mcpServers // {} | keys[]] | length' "$HOME/.claude.json" 2>/dev/null || echo 0)"

    printf 'MCP servers (disk): %s\n'      "$mcp"
    printf 'Custom agents (disk): %s\n'    "$agents"
    printf 'Memory files (disk): %s\n'     "$memory"
    printf 'Skills (disk): %s\n'           "$skills"
}

# Construye el reporte completo en stdout.
ci_build_report() {
    local pane dir t
    pane="$(ci_find_claude_pane)"
    dir="$(ci_project_dir "$pane")"
    [ -n "$dir" ] || dir="$PWD"
    t="$(ci_transcript_for_dir "$dir")"

    echo "Context Usage  ·  fuente: transcript en disco (sin enviar /context)"
    echo "cwd: $dir"

    local fields model total input cc cr msgs
    fields="$(ci_usage_fields "$t")"
    if [ -z "$fields" ]; then
        echo
        echo "No se encontró transcript con datos de uso para este cwd."
        echo "Transcript buscado en: $CI_PROJECTS_DIR/$(ci_slug_for_dir "$dir")/"
        echo "Para el desglose oficial, abre la vista live (tecla L) — esa SÍ envía /context."
        echo
        echo "On-disk inventory:"
        _ci_disk_inventory "$dir"
        return 0
    fi

    read -r model total input cc cr msgs <<<"$fields"
    echo "transcript: $t"
    echo "Model: $model"
    echo

    local win pct free freepct newt
    win="$(ci_window_for_model "$model" "$total")"
    pct=$(awk -v a="$total" -v b="$win" 'BEGIN{printf "%.1f", (b>0)?a*100/b:0}')
    free=$((win - total)); [ "$free" -lt 0 ] && free=0
    freepct=$(awk -v a="$free" -v b="$win" 'BEGIN{printf "%.1f", (b>0)?a*100/b:0}')
    newt=$((input + cc))

    printf 'Tokens: %s / %s  (%s%%)\n' "$(ci_fmt_tokens "$total")" "$(ci_fmt_tokens "$win")" "$pct"
    printf 'Free space: %s  (%s%%)\n'  "$(ci_fmt_tokens "$free")" "$freepct"
    local bar
    bar=$(awk -v p="$pct" 'BEGIN{f=int(p/100*24+0.5); s=""; for(i=0;i<24;i++) s=s (i<f?"█":"░"); print s}')
    printf 'Usage: [%s] %s%%\n' "$bar" "$pct"
    echo
    echo "Breakdown (del transcript):"
    printf '  Cached prefix (system+tools+memory+skills+historial): %s\n' "$(ci_fmt_tokens "$cr")"
    printf '  New this turn (input + cache write):                  %s\n' "$(ci_fmt_tokens "$newt")"
    printf '  Messages/history: incluido en el cached prefix · %s mensajes\n' "$msgs"
    echo
    echo "System prompt / System tools / Messages (split exacto por categoría):"
    echo "  requiere /context — usa la vista live (tecla L) para el desglose oficial."
    echo
    echo "On-disk inventory:"
    _ci_disk_inventory "$dir"
}

# Devuelve la ruta del reporte cacheado, reconstruyéndolo si está obsoleto.
ci_get_context() {
    if [ -f "$CI_CACHE_FILE" ]; then
        local mtime now age
        mtime="$(stat -c %Y "$CI_CACHE_FILE" 2>/dev/null || echo 0)"
        now="$(date +%s)"
        age=$((now - mtime))
        [ "$age" -lt "$CI_CACHE_TTL" ] && { echo "$CI_CACHE_FILE"; return 0; }
    fi
    ci_build_report > "$CI_CACHE_FILE"
    echo "$CI_CACHE_FILE"
}

# --- Opt-in: scrape del REPL en vivo (envía /context) -----------------------
# Sólo para la vista 'live'. Sondea hasta estabilizar y captura el panel.
ci_capture_live() {
    local pane out prev="" cur="" i=0
    pane="$(ci_find_claude_pane)"
    out="$(mktemp)"
    if [ -z "$pane" ]; then
        echo "No se encontró un panel ejecutando Claude Code." > "$out"
        echo "$out"; return 1
    fi
    tmux send-keys -t "$pane" '/context' Enter
    # -e = preserva secuencias de color ANSI (el pager las pinta con less -R).
    while [ "$i" -lt 25 ]; do
        sleep 0.3
        cur="$(tmux capture-pane -e -p -t "$pane")"
        [ -n "$cur" ] && [ "$cur" = "$prev" ] && break
        prev="$cur"; i=$((i + 1))
    done
    printf '%s\n' "$cur" > "$out"
    echo "$out"
}
