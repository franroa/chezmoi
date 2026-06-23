#!/usr/bin/env bash
# Despachador de navegadores agentsview. Corre DENTRO de un display-popup abierto
# con -e TMUX_PARENT_CLIENT=#{client_tty} (para que la tecla o pueda switch-client)
# y -d #{pane_current_path} (para marcar la sesión EN VIVO).
#
# Cada hoja del menú K llama aquí con un grupo + faceta; produce filas
# "<display>\t<session_id>" y las pasa al motor vi sessions_fzf.sh. Pickers
# (project/agent/grade/outcome) eligen un valor y re-ejecutan acotados.
#
#   av_browse.sh sessions all|name|content|failures
#   av_browse.sh sessions grade|project|agent|outcome <valor>
#   av_browse.sh pick    project|agent|grade|outcome
#   av_browse.sh secrets all|scan | secrets project|agent <valor> | secrets pick project|agent
#   av_browse.sh stats | projects
#   av_browse.sh _content <q>                (interno: filas para FTS en vivo)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/_lib.sh"
ENGINE="$DIR/sessions_fzf.sh"
SELF="$DIR/av_browse.sh"
LIST_LIMIT=500

ci_have_agentsview || { echo "agentsview no está instalado."; sleep 1.5; exit 0; }
command -v fzf >/dev/null 2>&1 || { echo "fzf no encontrado."; sleep 1.5; exit 0; }

cur_id() { local t; t="$(ci_transcript_for_dir "$PWD" 2>/dev/null)"; ci_session_id "$t"; }

# session list (con flags) -> filas "<display>\t<id>". Marca la sesión viva ▶.
rows_session_list() {
    agentsview session list --limit "$LIST_LIMIT" --format json "$@" 2>/dev/null | jq -r \
        --arg cur "$(cur_id)" '
        .sessions | sort_by(.started_at) | reverse | .[]
        | ((.first_message // "(sin mensaje)") | gsub("[\n\r\t]+"; " ")) as $name
        | (if .id == $cur then "▶ " else "  " end) as $mark
        | [ ($mark + ($name | .[0:44])), (.project // ""),
            ((.started_at // "") | .[0:16]), (.health_grade // "?"), .id ] | @tsv' 2>/dev/null \
    | awk -F'\t' '{ printf "%-46s  %-14s  %-16s  %-2s\t%s\n", $1,$2,$3,$4,$5 }'
}

# FTS por contenido -> filas "<snippet>\t<id>".
rows_content() {
    local q="${1:-}"
    [ -z "$q" ] && { rows_session_list; return; }   # query vacía: lista normal
    agentsview session search "$q" --format json 2>/dev/null | jq -r '
        .matches[]? | [ ((.snippet // "") | gsub("[\n\r\t]+"; " ") | .[0:60]),
                        (.project // ""), (.role // ""), .session_id ] | @tsv' 2>/dev/null \
    | awk -F'\t' '{ printf "%-62s  %-12s  %-9s\t%s\n", $1,$2,$3,$4 }'
}

# secrets findings -> filas "<rule> <project> <redacted>\t<id>".
rows_secrets() {
    agentsview secrets list --limit "$LIST_LIMIT" --format json "$@" 2>/dev/null | jq -r '
        (.findings // .)[]? | [ ((.rule_name // "?")|.[0:24]), (.project // ""),
                                ((.redacted_match // "")|.[0:30]), .session_id ] | @tsv' 2>/dev/null \
    | awk -F'\t' '{ printf "%-24s  %-14s  %-30s\t%s\n", $1,$2,$3,$4 }'
}

# Motor con filas desde stdin (fichero temporal).
engine_with() { local f; f="$(mktemp)"; cat > "$f"; SESS_HEADER="${1:-}" bash "$ENGINE" "$f"; rm -f "$f"; }

# Picker de valores: stdin = candidatos; imprime la elección (o vacío).
pick_value() {
    fzf --reverse --height=100% --cycle --prompt="${1:-elige}> " \
        --header='escribe filtra · enter elige · esc/q sale' \
        --bind 'q:abort' --bind 'ctrl-j:down' --bind 'ctrl-k:up'
}

group="${1:-}"; kind="${2:-}"; val="${3:-}"
case "$group" in
  sessions)
    case "$kind" in
      all|name|"")  rows_session_list | engine_with "SESIONES (nombre): i+escribe filtra · o abre · enter detalle" ;;
      content)      SESS_HEADER="CONTENIDO (FTS): i+escribe busca en mensajes · o abre · enter detalle" \
                    SESS_PROMPT="FTS ▶ " \
                    SESS_RELOAD="bash '$SELF' _content {q}" bash "$ENGINE" ;;
      failures)     rows_session_list --min-tool-failures 1 | engine_with "SESIONES con fallos de tool" ;;
      grade)        rows_session_list --health-grade "$val"   | engine_with "SESIONES grado $val" ;;
      project)      rows_session_list --project "$val"        | engine_with "SESIONES proyecto $val" ;;
      agent)        rows_session_list --agent "$val"          | engine_with "SESIONES agente $val" ;;
      outcome)      rows_session_list --outcome "$val"        | engine_with "SESIONES outcome $val" ;;
    esac ;;
  _content)  rows_content "$kind" ;;          # $kind = query (interno, reload)
  pick)
    case "$kind" in
      project) c="$(agentsview projects 2>/dev/null | awk 'NR>1{print $1}' | pick_value proyecto)"; [ -n "$c" ] && exec bash "$SELF" sessions project "$c" ;;
      agent)   c="$(agentsview session list --limit 500 --format json 2>/dev/null | jq -r '[.sessions[].agent]|unique|.[]' | pick_value agente)"; [ -n "$c" ] && exec bash "$SELF" sessions agent "$c" ;;
      grade)   c="$(printf 'A\nB\nC\nD\nF\n' | pick_value grado)"; [ -n "$c" ] && exec bash "$SELF" sessions grade "$c" ;;
      outcome) c="$(printf 'completed\nabandoned\nunknown\n' | pick_value outcome)"; [ -n "$c" ] && exec bash "$SELF" sessions outcome "$c" ;;
    esac ;;
  secrets)
    case "$kind" in
      all|"")  rows_secrets | engine_with "SECRETOS detectados (redactados) · enter detalle · o abre" ;;
      project) rows_secrets --project "$val" | engine_with "SECRETOS proyecto $val" ;;
      agent)   rows_secrets --agent "$val"   | engine_with "SECRETOS agente $val" ;;
      scan)    echo "Escaneando secretos…"; agentsview secrets scan >/dev/null 2>&1; rows_secrets | engine_with "SECRETOS (tras scan)" ;;
      pick)
        case "$val" in
          project) c="$(agentsview projects 2>/dev/null | awk 'NR>1{print $1}' | pick_value proyecto)"; [ -n "$c" ] && exec bash "$SELF" secrets project "$c" ;;
          agent)   c="$(agentsview session list --limit 500 --format json 2>/dev/null | jq -r '[.sessions[].agent]|unique|.[]' | pick_value agente)"; [ -n "$c" ] && exec bash "$SELF" secrets agent "$c" ;;
        esac ;;
    esac ;;
  projects)
    c="$(agentsview projects 2>/dev/null | awk 'NR>1{print $1"  ("$2" ses)"}' | pick_value proyecto | awk '{print $1}')"
    [ -n "$c" ] && exec bash "$SELF" sessions project "$c" ;;
  stats)
    { echo "═══ Stats (agentsview, ventana 28d) ═══"; echo; agentsview stats 2>&1; } | less -R ;;
  *) echo "uso: av_browse.sh sessions|pick|secrets|projects|stats …"; sleep 1.5 ;;
esac
