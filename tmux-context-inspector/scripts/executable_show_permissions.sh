#!/usr/bin/env bash
# Consumer: permissions.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
pane="$(ci_find_claude_pane)"
proj="$(ci_project_dir "$pane")"
out="$(mktemp)"
{
    echo "═══ Permisos ═══"
    echo
    echo "— Archivos de settings con permisos:"
    for f in "$HOME/.claude/settings.json" \
             "$proj/.claude/settings.json" \
             "$proj/.claude/settings.local.json"; do
        [ -f "$f" ] && echo "  • $f"
    done
    echo
    echo "Para revisar/editar reglas en vivo: /permissions"
} > "$out"
ci_popup_file "$out"
