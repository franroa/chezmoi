#!/usr/bin/env bash
# Consumer: skills loaded in the session. Enriched by reading disk.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
pane="$(ci_find_claude_pane)"
proj="$(ci_project_dir "$pane")"
out="$(mktemp)"

list_skills() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    echo "  $dir:"
    find "$dir" -maxdepth 1 -mindepth 1 -type d -printf '    • %f\n' 2>/dev/null | sort
}

{
    echo "═══ Skills ═══"
    echo
    echo "— Del reporte de contexto (transcript, sin /context):"
    ci_section "$cap" "skill"
    echo
    echo "— Skills en disco:"
    list_skills "$HOME/.claude/skills"
    list_skills "$proj/.claude/skills"
} > "$out"
ci_popup_file "$out"
