#!/usr/bin/env bash
# Abre la WEB UI de agentsview en el navegador. Ahí viven las recomendaciones /
# insights de mejora de prompts (la CLI NO las expone: health/stats/get sólo dan
# señales y métricas; los insights generados están sólo en `agentsview serve`).
#
#   open_web.sh session    -> /sessions/<id de la sesión ACTUAL>   (tecla w)
#   open_web.sh insights   -> /insights  (dashboard global)        (tecla W)
#
# Arranca `agentsview serve` si no está vivo (una sola vez, persistente), luego
# abre la ruta. Siempre muestra la URL en el status por si el navegador no abre
# (p.ej. sin DISPLAY en el servidor tmux).
#
# Env: AV_WEB_PORT (8080), AV_WEB_HOST (127.0.0.1).
# Doc: https://www.agentsview.io/insights/
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/_lib.sh"

HOST="${AV_WEB_HOST:-127.0.0.1}"
PORT="${AV_WEB_PORT:-8080}"
BASE="http://$HOST:$PORT"

ci_have_agentsview || { tmux display-message "agentsview no está instalado"; exit 0; }

is_up() { command -v curl >/dev/null 2>&1 && curl -fsS -o /dev/null "$BASE/" 2>/dev/null; }

# Arranca el servidor si no responde. nohup + disown -> sobrevive al run-shell.
if ! is_up; then
    nohup agentsview serve --no-browser --host "$HOST" --port "$PORT" \
        >/tmp/agentsview-serve.log 2>&1 &
    disown 2>/dev/null || true
    for _ in $(seq 1 40); do is_up && break; sleep 0.25; done
fi

# Resuelve la ruta.
route="/insights"
case "${1:-insights}" in
    session)
        pane="$(ci_find_claude_pane)"
        dir="$(ci_project_dir "$pane")"; [ -n "$dir" ] || dir="$PWD"
        id="$(ci_session_id "$(ci_transcript_for_dir "$dir")")"
        if [ -n "$id" ]; then route="/sessions/$id"
        else route="/insights"; fi ;;
    insights|"") route="/insights" ;;
    *)           route="/$1" ;;
esac
url="$BASE$route"

# Abre el navegador con el primer opener disponible (o BROWSER).
opener=""
for c in xdg-open sensible-browser wslview open; do
    command -v "$c" >/dev/null 2>&1 && { opener="$c"; break; }
done
[ -z "$opener" ] && [ -n "${BROWSER:-}" ] && opener="$BROWSER"
if [ -n "$opener" ]; then
    nohup "$opener" "$url" >/dev/null 2>&1 &
    disown 2>/dev/null || true
fi

tmux display-message "agentsview web: $url"
