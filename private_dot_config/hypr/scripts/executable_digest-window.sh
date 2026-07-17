#!/usr/bin/env bash
# Rendered inside the "Open digest" foot scratchpad (app-id digest-scratch),
# toggled like the alt-1/alt-2 scratchpads (toggle-digest.sh / Alt+4).
# Shows the digest that was last sent (GitLab MRs + top Slack threads, cached by
# morning-digest.sh) plus TODAY'S Google Calendar agenda via gcalcli.
set -uo pipefail

# foot inherits the panel/hyprland env; make sure our tools are reachable.
export PATH="/home/linuxbrew/.linuxbrew/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/morning-digest"
DIGEST_FILE="$STATE_DIR/last_digest.txt"
GCAL="$(command -v gcalcli || echo "$HOME/.local/bin/gcalcli")"

render() {
    clear
    if [[ -r "$DIGEST_FILE" ]]; then
        cat "$DIGEST_FILE"
    else
        echo "☀ Morning digest"
        echo "(no digest cached yet — it is written when the morning notification"
        echo " fires. Generate one now with:  morning-digest.sh force)"
    fi
    echo
    echo "────────────────────────────────────────────────────────"
    echo "📅 Today's calendar"
    echo "────────────────────────────────────────────────────────"
    if [[ -x "$GCAL" ]] && "$GCAL" list >/dev/null 2>&1 </dev/null; then
        "$GCAL" agenda today tomorrow 2>/dev/null </dev/null || echo "(could not fetch agenda)"
    else
        echo "⚠ Google Calendar not connected yet — one-time OAuth setup needed:"
        echo "    1. console.cloud.google.com → enable 'Google Calendar API'"
        echo "    2. create an OAuth client ID (Desktop app) → copy id + secret"
        echo "    3. gcalcli --client-id=ID --client-secret=SECRET init"
        echo "  (opens a browser once; token is stored in ~/.config/gcalcli)"
    fi
    echo
    echo "────────────────────────────────────────────────────────"
    echo "(any key = refresh · q = close · toggle with Alt+4)"
}

# Keep the scratchpad open and toggleable (like the alt-1 aoe terminal): block
# on a keypress rather than dropping to a shell. Any key re-renders (refreshing
# the calendar); q or Ctrl-D closes it. Toggling to ws 99 just parks this loop.
while true; do
    render
    IFS= read -rsn1 key || break
    [[ "$key" == "q" ]] && break
done
