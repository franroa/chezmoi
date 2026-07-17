#!/usr/bin/env bash
# Salud e inteligencia de la sesión ACTUAL (tecla h).
#
# Fuente: agentsview `health <id>` sobre el transcript JSONL del cwd del panel
# Claude. Muestra grade+score, outcome (con confianza) y el desglose de señales
# (fallos de tool, reintentos, edit churn, secretos, compactaciones, presión de
# contexto), más el timeline de modelos y modos (av_model_timeline.sh: qué
# modelo se usó en cada tramo y el permissionMode real de cada tramo — ground
# truth del transcript, cubre Shift+Tab y sesiones que arrancan en plan mode).
# Es la contraparte por-sesión de la vista H (overview global).
#
# Doc: https://www.agentsview.io/session-intelligence/#agentsview-health
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_recommend.sh"

out="$(mktemp)"

if ci_have_agentsview; then
    pane="$(ci_find_claude_pane)"
    dir="$(ci_project_dir "$pane")"; [ -n "$dir" ] || dir="$PWD"
    t="$(ci_transcript_for_dir "$dir")"
    id="$(ci_session_id "$t")"
    ci_sync_session "$t"
    {
        echo "═══ Salud e inteligencia de sesión (agentsview) ═══"
        echo
        if [ -z "$id" ]; then
            echo "No se encontró transcript para este cwd."
            echo "Buscado en: $CI_PROJECTS_DIR/$(ci_slug_for_dir "$dir")/"
        else
            echo "— health  ·  id: $id"
            echo
            health_json="$(agentsview health "$id" --json 2>/dev/null)"
            agentsview health "$id" 2>&1
            echo
            echo "— modelos y modos (timeline: modelo por mensaje + permissionMode real)"
            timeline_text="$("$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/av_model_timeline.sh" "$id" 2>/dev/null)"
            if [ -n "$timeline_text" ]; then
                printf '%s\n' "$timeline_text"
            else
                echo "  (timeline no disponible)"
            fi
            ci_session_recommendations "$id" "$health_json" "$timeline_text"
        fi
        echo
        echo "Overview global de salud: vista H  ·  coste de sesión: vista o"
    } > "$out"
else
    {
        echo "═══ Salud e inteligencia de sesión ═══"
        echo
        echo "agentsview no está instalado."
        echo "Instálalo para grade/outcome y el desglose de señales por sesión."
    } > "$out"
fi

ci_popup_file "$out"
