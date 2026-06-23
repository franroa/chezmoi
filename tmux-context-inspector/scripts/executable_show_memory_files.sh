#!/usr/bin/env bash
# Consumer: memory files / CLAUDE.md hierarchy.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
pane="$(ci_find_claude_pane)"
proj="$(ci_project_dir "$pane")"
out="$(mktemp)"

# CLAUDE.md hierarchy: from the project root up to $HOME, plus the user global.
list_claude_md() {
    local dir="$proj"
    while [ -n "$dir" ] && [ "$dir" != "/" ]; do
        [ -f "$dir/CLAUDE.md" ]       && echo "  • $dir/CLAUDE.md"
        [ -f "$dir/.claude/CLAUDE.md" ] && echo "  • $dir/.claude/CLAUDE.md"
        [ "$dir" = "$HOME" ] && break
        dir="$(dirname "$dir")"
    done
    [ -f "$HOME/.claude/CLAUDE.md" ] && echo "  • $HOME/.claude/CLAUDE.md"
}

{
    echo "═══ Archivos de memoria / CLAUDE.md ═══"
    echo
    echo "— Del reporte de contexto (transcript, sin /context):"
    ci_section "$cap" "memory"
    echo
    echo "— Jerarquía CLAUDE.md detectada:"
    list_claude_md
    echo
    echo "Para gestionar memoria en vivo: /memory"
} > "$out"
ci_popup_file "$out"
