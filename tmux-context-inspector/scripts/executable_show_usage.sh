#!/usr/bin/env bash
# Consumer: cross-session usage/cost (daily). agentsview-only, no id.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

out="$(mktemp)"
{
    echo "═══ Uso y coste diario — todas las sesiones (agentsview) ═══"
    echo
    if ! ci_have_agentsview; then
        echo "agentsview no está instalado — sin resumen de uso."
    else
        agentsview usage daily 2>&1
    fi
} > "$out"
ci_popup_file "$out"
