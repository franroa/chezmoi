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

# Refresca la DB local antes de listar: `session list` lee la DB (SQLite), NO los
# JSONL en vivo, así que sesiones nuevas o RE-TITULADAS (p.ej. *_WIP) no aparecen
# hasta sincronizar. Incremental (~0.2s en estado estable). Con timeout para que
# un remote_hosts SSH mal configurado nunca cuelgue el popup.
ci_sync_db() {
    local t=""
    command -v timeout >/dev/null 2>&1 && t="timeout 8"
    $t agentsview sync >/dev/null 2>&1 || true
}

cur_id() { local t; t="$(ci_transcript_for_dir "$PWD" 2>/dev/null)"; ci_session_id "$t"; }

# Session title map -> "<id>\t<title>". agentsview exposes no title, so read it
# from the transcripts (same source `claude --resume` shows, like file_label in
# aoe-claude-sessions.sh): a custom-title beats an ai-title, and the last write
# of each wins. One grep pass over all JSONL, resolved in awk (~0.3s).
rows_titles() {
    grep -rhE '"type":"(custom-title|ai-title)"' "$CI_PROJECTS_DIR"/*/*.jsonl 2>/dev/null \
    | jq -r 'select(.sessionId and (.customTitle or .aiTitle))
             | [ .sessionId, .type,
                 ((.customTitle // .aiTitle) | gsub("[\t\r\n]+"; " ")) ] | @tsv' 2>/dev/null \
    | awk -F'\t' '{ p=($2=="custom-title")?2:1; if (p>=pr[$1]) { pr[$1]=p; t[$1]=$3 } }
                  END{ for (id in t) printf "%s\t%s\n", id, t[id] }'
}

# session list (con flags) -> filas "<display>\t<id>". Marca la sesión viva ▶.
# El nombre = título de la sesión (custom/ai-title), y si no tiene, first_message.
rows_session_list() {
    local tmap; tmap="$(mktemp)"; rows_titles > "$tmap"
    agentsview session list --limit "$LIST_LIMIT" --include-one-shot --format json "$@" 2>/dev/null | jq -r '
        .sessions | sort_by(.started_at) | reverse | .[]
        | [ .id, ((.first_message // "") | gsub("[\n\r\t]+"; " ")),
            (.project // ""), ((.started_at // "") | .[0:16]), (.health_grade // "?") ] | @tsv' 2>/dev/null \
    | awk -F'\t' -v cur="$(cur_id)" -v tmap="$tmap" '
        BEGIN{ while ((getline l < tmap) > 0) { i=index(l,"\t"); title[substr(l,1,i-1)]=substr(l,i+1) } }
        { id=$1; fm=$2; proj=$3; started=$4; grade=$5;
          name=(id in title && title[id]!="") ? title[id] : fm;
          if (name=="") name="(sin nombre)";
          mark=(id==cur)?"▶ ":"  ";
          printf "%-46s  %-14s  %-16s  %-2s\t%s\n", mark substr(name,1,44), proj, started, grade, id }'
    rm -f "$tmap"
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
# Sync once per popup open (NOT on _content: that re-invokes on every keystroke).
[ "$group" = _content ] || ci_sync_db
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
