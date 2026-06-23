#!/usr/bin/env bash
# Consumer: messages / conversation history.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
out="$(mktemp)"
{
    echo "═══ Mensajes / historial ═══"
    echo
    ci_section "$cap" "messages"
    echo
    echo "Si los mensajes dominan el contexto, compacta con: /compact"
} > "$out"
ci_popup_file "$out"
