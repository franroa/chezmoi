#!/usr/bin/env bash
# Consumer: System tools.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
out="$(mktemp)"
{
    echo "═══ System tools ═══"
    echo
    echo "El conteo exacto de tokens de tools sólo lo da /context."
    echo "Abre la vista live (tecla L) para el desglose oficial por categoría."
    echo
    echo "Contexto total actual (del transcript):"
    ci_section "$cap" "Tokens:"
} > "$out"
ci_popup_file "$out"
