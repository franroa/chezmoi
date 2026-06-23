#!/usr/bin/env bash
# Consumer: custom agents. Enriched by reading .claude/agents/.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
pane="$(ci_find_claude_pane)"
proj="$(ci_project_dir "$pane")"
out="$(mktemp)"

list_agents() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    echo "  $dir:"
    find "$dir" -maxdepth 1 -name '*.md' -printf '    • %f\n' 2>/dev/null | sort
}

{
    echo "═══ Agentes personalizados ═══"
    echo
    echo "— Del reporte de contexto (transcript, sin /context):"
    ci_section "$cap" "agent"
    echo
    echo "— Definiciones en disco:"
    list_agents "$HOME/.claude/agents"
    list_agents "$proj/.claude/agents"
} > "$out"
ci_popup_file "$out"
