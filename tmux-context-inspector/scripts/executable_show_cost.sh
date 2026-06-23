#!/usr/bin/env bash
# Consumer: cost and utilization.
#
# Preferred source: agentsview `session usage <id>` (output tokens, peak
# context, USD cost per model) over the same JSONL transcript. If agentsview is
# missing, falls back to the summary derived from /context (free space + tokens).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

out="$(mktemp)"

if ci_have_agentsview; then
    pane="$(ci_find_claude_pane)"
    dir="$(ci_project_dir "$pane")"; [ -n "$dir" ] || dir="$PWD"
    t="$(ci_transcript_for_dir "$dir")"
    id="$(ci_session_id "$t")"
    ci_sync_session "$t"
    {
        echo "═══ Coste y utilización (agentsview) ═══"
        echo
        if [ -z "$id" ]; then
            echo "No se encontró transcript para este cwd."
            echo "Buscado en: $CI_PROJECTS_DIR/$(ci_slug_for_dir "$dir")/"
        else
            echo "— session usage  ·  id: $id"
            echo
            agentsview session usage "$id" 2>&1
        fi
        echo
        echo "Cross-sesión (coste diario): vista u  ·  desglose vivo: /cost"
    } > "$out"
else
    cap="$(ci_get_context)"
    {
        echo "═══ Coste y utilización ═══"
        echo
        echo "— Resumen de utilización (de /context):"
        ci_section "$cap" "free space"
        ci_section "$cap" "tokens"
        echo
        echo "Para el desglose de coste de la sesión: /cost"
        echo "(instala agentsview para tokens/pico/coste por modelo)"
    } > "$out"
fi

ci_popup_file "$out"
