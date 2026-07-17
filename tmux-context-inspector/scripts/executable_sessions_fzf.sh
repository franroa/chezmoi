#!/usr/bin/env bash
# Motor fzf modo vi para listas "<display>\t<session_id>". Reusado por todos los
# navegadores agentsview (sesiones, secretos, por grado, etc).
#
#   $1            fichero de filas "<display>\t<id>"  (o vacío si SESS_RELOAD)
# Env opcional:
#   SESS_HEADER   texto de cabecera
#   SESS_PROMPT   prompt de modo NORMAL (def "NORMAL ▶ ")
#   SESS_RELOAD   comando que emite filas para FTS en vivo (usa {q}); si está,
#                 escribir en modo buscar dispara reload (búsqueda por contenido)
#
# Modos vi:
#   NORMAL: j/k mueve · g/G · o = abrir sesión aoe nueva · enter = detalle
#           · i o / = buscar · q sale
#   BUSCAR: escribe para filtrar (o FTS si SESS_RELOAD) · alt-o abrir · esc NORMAL
#
# "Abrir" reusa aoe-claude-sessions.sh --enter <id> (misma lógica que prefix A l):
# nueva tmux session cc-<repo>-<id8> con claude --resume, switch al cliente padre.
set -uo pipefail

AOE="$HOME/.config/tmux/scripts/aoe-claude-sessions.sh"

if [ "${1:-}" = "--detail" ]; then
    id="${2:-}"
    {
        echo "═══ Sesión $id ═══"; echo
        echo "— usage:";  agentsview session usage "$id" 2>&1; echo
        echo "— health:"; agentsview health "$id" 2>&1
    } | less -R
    exit 0
fi

rows="${1:-}"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
NK='j,k,g,G,o,q,i'
header="${SESS_HEADER:-NORMAL: j/k mueve · o abre sesión aoe · enter detalle · i buscar · q sale}"
prompt="${SESS_PROMPT:-NORMAL ▶ }"

binds=(
    --bind 'j:down' --bind 'k:up'
    --bind 'g:first' --bind 'G:last'
    --bind 'ctrl-d:half-page-down' --bind 'ctrl-u:half-page-up'
    --bind 'q:abort' --bind 'ctrl-g:abort'
    --bind "enter:execute(bash '$SELF' --detail {2})"
    --bind "o:become(bash '$AOE' --enter-titled {2})"
    --bind "alt-o:become(bash '$AOE' --enter-titled {2})"
    --bind "i:enable-search+unbind($NK)+change-prompt(buscar> )"
    --bind "/:enable-search+unbind($NK)+change-prompt(buscar> )"
    --bind "esc:disable-search+rebind($NK)+change-prompt($prompt)"
)
# Modo contenido (FTS en vivo): el reload se dispara al escribir.
if [ -n "${SESS_RELOAD:-}" ]; then
    binds+=( --bind "change:reload($SESS_RELOAD)" --bind "start:reload($SESS_RELOAD)" )
fi

run() {
    fzf --delimiter='\t' --with-nth=1 --nth=1 --ansi --no-sort --reverse --cycle \
        --height=100% --disabled --prompt="$prompt" --header="$header" \
        --preview="agentsview session usage {2} 2>/dev/null; echo; agentsview health {2} 2>/dev/null" \
        --preview-window='right,55%,wrap' "${binds[@]}" "$@"
}

if [ -n "${SESS_RELOAD:-}" ]; then
    run < /dev/null
else
    [ -s "$rows" ] || { echo "Sin resultados."; sleep 1; exit 0; }
    run < "$rows"
fi
