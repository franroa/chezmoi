#!/usr/bin/env bash
# Consumer: files loaded into context this session.
#
# "Which files entered the context" = tool_use calls that pull file content
# (Read / Edit / Write / MultiEdit / NotebookEdit). Preferred source: agentsview
# `session tool-calls <id>` (maintained parser over the JSONL). If agentsview is
# missing, falls back to a direct jq scrape of the transcript. @-mentions and
# CLAUDE.md show up in the `f` view.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

pane="$(ci_find_claude_pane)"
dir="$(ci_project_dir "$pane")"; [ -n "$dir" ] || dir="$PWD"
t="$(ci_transcript_for_dir "$dir")"
out="$(mktemp)"

# "<count>\t<file_path>" per file, sorted desc by count. Via agentsview.
ci_context_files_av() {
    local id="$1"
    agentsview session tool-calls "$id" --format json 2>/dev/null | jq -r '
        [ .tool_calls[]?
          | select(.category=="Read" or .category=="Edit" or .category=="Write"
                   or .category=="MultiEdit" or .category=="NotebookEdit")
          | (try (.input_json | fromjson) catch {}) as $in
          | ($in.file_path // $in.notebook_path)
          | select(. != null)
        ]
        | group_by(.) | map({f: .[0], n: length})
        | sort_by(-.n)
        | .[] | "\(.n)\t\(.f)"
    ' 2>/dev/null
}

# Fallback: direct jq scrape of the transcript.
ci_context_files_jq() {
    [ -n "$t" ] && [ -f "$t" ] || return 1
    jq -rs '
        [ .[] | .message.content? // empty
          | select(type=="array") | .[]
          | select(.type=="tool_use")
          | select(.name=="Read" or .name=="Edit" or .name=="Write"
                   or .name=="MultiEdit" or .name=="NotebookEdit")
          | (.input.file_path // .input.notebook_path)
          | select(. != null)
        ]
        | group_by(.) | map({f: .[0], n: length})
        | sort_by(-.n)
        | .[] | "\(.n)\t\(.f)"
    ' "$t" 2>/dev/null
}

{
    if ci_have_agentsview; then
        echo "═══ Archivos cargados al contexto (agentsview) ═══"
    else
        echo "═══ Archivos cargados al contexto (esta sesión) ═══"
    fi
    echo
    if [ -z "$t" ] || [ ! -f "$t" ]; then
        echo "No se encontró transcript para este cwd."
        echo "Buscado en: $CI_PROJECTS_DIR/$(ci_slug_for_dir "$dir")/"
    else
        echo "transcript: $t"
        echo
        if ci_have_agentsview; then
            ci_sync_session "$t"
            rows="$(ci_context_files_av "$(ci_session_id "$t")")"
        else
            rows="$(ci_context_files_jq)"
        fi
        if [ -z "$rows" ]; then
            echo "Sin archivos leídos/editados todavía en esta sesión."
        else
            nfiles="$(printf '%s\n' "$rows" | grep -c .)"
            echo "— $nfiles archivos únicos (× = veces tocado, desc):"
            printf '%s\n' "$rows" | while IFS=$'\t' read -r n f; do
                printf '  • %3s×  %s\n' "$n" "$f"
            done
        fi
    fi
    echo
    echo "Nota: cuenta tool_use Read/Edit/Write/MultiEdit/NotebookEdit."
    echo "Para CLAUDE.md y memoria usa la vista f · para @-mentions, revisa el chat."
} > "$out"
ci_popup_file "$out"
