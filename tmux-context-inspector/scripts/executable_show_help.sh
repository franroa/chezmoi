#!/usr/bin/env bash
# Ayuda / mapa de teclas de la tabla context-inspector.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

ci_popup_text "$(cat <<'EOF'
═══ Context Inspector — mapa de teclas ═══

Activación:  <Prefix> K   y luego:

  VISTAS SINGLE (popup pager, leen transcript en disco o REPL):
  c   Contexto total + inventario (sin /context)
  L   Vista LIVE — envía /context al REPL (split oficial)
  y   System prompt                  (movido de s)
  t   System tools
  m   Servidores MCP + tokens        (+ /mcp)
  a   Agentes personalizados         (.claude/agents/)
  f   Memoria / jerarquía CLAUDE.md  (+ /memory)
  i   Archivos cargados al contexto  (agentsview session tool-calls)
  g   Mensajes / historial           (movido de h; tip /compact)
  h   Salud/inteligencia SESIÓN actual (agentsview health <id>)
  H   Salud/inteligencia OVERVIEW global (agentsview health + stats)
  p   Permisos                        (+ /permissions)
  k   Skills cargadas                 (.claude/skills/)
  o   Coste y utilización             (agentsview session usage)
  u   Uso/coste diario cross-sesión   (agentsview usage daily)

  NAVEGADORES agentsview (fzf MODO VI · o = abrir sesión aoe nueva):
  s ▸ Sesiones:  n nombre · c contenido(FTS) · p proyecto · a agente
                 g grado · O outcome · F con-fallos · r todas
  S ▸ Secretos:  l todos · p proyecto · a agente · x escanear
  x   Stats (ventana 28d, en less)
  r   Projects (elige proyecto -> sus sesiones)

  WEB UI agentsview (insights/recomendaciones de prompts — sólo en serve):
  w   Web UI · sesión ACTUAL (/sessions/<id>)
  W   Web UI · dashboard de insights global (/insights)

  ?   Esta ayuda          q / Esc   Cancelar / volver

fzf modo vi:  j/k mueve · g/G inicio/fin · i o / = buscar (escribe filtra;
  en 's c' es FTS en vivo) · esc vuelve a NORMAL · o abre la sesión en una
  tmux nueva (claude --resume, misma lógica que prefix A l) · enter = detalle.

Notas:
  • Vistas single: por defecto NO se envía /context (se lee el transcript en
    ~/.claude/projects). Sólo L envía /context.
  • o/i/c y los navegadores se apoyan en agentsview (mismo JSONL, parser
    mantenido); o/i caen a jq si agentsview no está.
  • Ajustes: CI_POPUP_WIDTH, CI_POPUP_HEIGHT, CI_CACHE_TTL, CI_CONTEXT_WINDOW.
EOF
)"
