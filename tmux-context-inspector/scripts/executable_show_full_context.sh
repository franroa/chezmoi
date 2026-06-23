#!/usr/bin/env bash
# Full context view (derived from the transcript) + authoritative peak from
# agentsview. The per-category inventory comes from this report; agentsview only
# contributes the peak context figure (it has no per-category split).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"

cap="$(ci_get_context)"
out="$(mktemp)"
cp "$cap" "$out"

if ci_have_agentsview; then
    pane="$(ci_find_claude_pane)"
    dir="$(ci_project_dir "$pane")"; [ -n "$dir" ] || dir="$PWD"
    t="$(ci_transcript_for_dir "$dir")"
    id="$(ci_session_id "$t")"
    if [ -n "$id" ]; then
        ci_sync_session "$t"
        peak="$(agentsview session usage "$id" --format json 2>/dev/null \
                | jq -r '.peak_context_tokens // empty' 2>/dev/null)"
        if [ -n "$peak" ]; then
            {
                echo
                echo "— agentsview (autoritativo, sobre el mismo JSONL):"
                printf '  Peak ctx: %s (%s tokens)\n' "$(ci_fmt_tokens "$peak")" "$peak"
                echo "  Coste/modelo: vista o · cross-sesión: vista u"
            } >> "$out"
        fi
    fi
fi

ci_popup_file "$out"
