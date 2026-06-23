#!/usr/bin/env bash
# Consumer: MCP servers + tokens. Enriched by reading disk.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
pane="$(ci_find_claude_pane)"
proj="$(ci_project_dir "$pane")"
out="$(mktemp)"
{
    echo "═══ Servidores MCP ═══"
    echo
    echo "— Del reporte de contexto (transcript, sin /context):"
    ci_section "$cap" "mcp"
    echo
    echo "— Configuración en disco:"
    for f in "$proj/.mcp.json" "$proj/.claude/.mcp.json" "$HOME/.claude.json"; do
        [ -f "$f" ] && echo "  • $f"
    done
    echo
    echo "Para el detalle en vivo de cada servidor: /mcp"
} > "$out"
ci_popup_file "$out"
