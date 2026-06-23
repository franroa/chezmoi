#!/usr/bin/env bash
#
# tmux-context-inspector
# Leader <Prefix> K -> tabla de teclas `context-inspector`. Vistas single de
# contexto/config (leen el transcript en disco o el REPL) + navegadores
# agentsview en submenús (fzf modo vi). (K y no C: prefix+C ya es el TUI de
# pipelines de GitLab.)
#
# Estructura:
#   K c/L/y/t/m/a/f/i/g/p/k/o/u   vistas single (popup pager)
#   K h    Salud/inteligencia de la SESIÓN ACTUAL (agentsview health <id>)
#   K H    Salud/inteligencia OVERVIEW global (agentsview health + stats)
#   K s ▸  Sesiones (fzf vi):  n nombre · c contenido(FTS) · p proyecto ·
#                              a agente · g grado · O outcome · F con-fallos · r todas
#   K S ▸  Secretos (fzf vi):  l todos · p proyecto · a agente · x escanear
#   K w    Web UI sesión ACTUAL (/sessions/<id>)   K W  Web UI insights global
#   K x    Stats (less)        K r  Projects (picker -> sesiones)        K ? ayuda
# (h minúscula = sesión actual, H mayúscula = overview, según la doc agentsview
#  session-intelligence/#agentsview-health. Mensajes se movió de h a g.)
#
# Navegadores corren en display-popup con -e TMUX_PARENT_CLIENT (la tecla o abre
# una sesión aoe nueva: reusa aoe-claude-sessions.sh, igual que prefix A l).

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$CURRENT_DIR/scripts"

tmux bind-key K switch-client -T context-inspector

# Limpia binds de iteraciones previas que se han plegado en submenús
# (recargar sólo AÑADE; estas teclas ya no existen en la tabla root).
for _k in l v /; do tmux unbind-key -T context-inspector "$_k" 2>/dev/null; done

# Vista single -> popup pager (run-shell).
_ci_bind() { tmux bind-key -T context-inspector "$1" run-shell -b "'$SCRIPTS/$2'"; }
# Igual pero pasando un argumento al script (la ruta no se mete en las comillas).
_ci_runsh() { tmux bind-key -T context-inspector "$1" run-shell -b "'$SCRIPTS/$2' $3"; }
# Entrar en un submenú (sub-tabla de teclas).
_ci_grp()  { tmux bind-key -T "$1" "$2" switch-client -T "$3"; }
# Hoja-navegador -> display-popup interactivo (fzf vi) con cliente padre + cwd.
_ci_pop()  {
    tmux bind-key -T "$1" "$2" display-popup -E \
        -e TMUX_PARENT_CLIENT="#{client_tty}" -d "#{pane_current_path}" \
        -w 92% -h 88% "'$SCRIPTS/av_browse.sh' $3"
}
# q / Esc de una sub-tabla -> vuelve a la tabla root.
_ci_exit() {
    tmux bind-key -T "$1" q      switch-client -T root
    tmux bind-key -T "$1" Escape switch-client -T root
}

# --- Vistas single (contexto / config) --------------------------------------
_ci_bind c show_full_context.sh
_ci_bind L show_live_context.sh
_ci_bind y show_system_prompt.sh      # (movido de s: s ahora es el submenú Sesiones)
_ci_bind t show_system_tools.sh
_ci_bind m show_mcp.sh
_ci_bind a show_agents.sh
_ci_bind f show_memory_files.sh
_ci_bind i show_context_files.sh
_ci_bind g show_messages.sh        # (movido de h: h ahora es salud de sesión)
_ci_bind h show_health.sh          # salud/inteligencia de la SESIÓN ACTUAL
_ci_bind p show_permissions.sh
_ci_bind k show_skills.sh
_ci_bind o show_cost.sh
_ci_bind u show_usage.sh
_ci_bind '?' show_help.sh

# --- Submenús agentsview (navegadores fzf vi) -------------------------------
_ci_grp context-inspector s ci-sessions
_ci_grp context-inspector S ci-secrets
_ci_bind H show_health_overview.sh   # salud/inteligencia OVERVIEW global
_ci_pop context-inspector x 'stats'
_ci_pop context-inspector r 'projects'
# Web UI agentsview (recomendaciones/insights de prompts; sólo en serve, no CLI).
_ci_runsh w open_web.sh session      # /sessions/<id> de la sesión ACTUAL
_ci_runsh W open_web.sh insights     # /insights dashboard global

# Sesiones
_ci_pop ci-sessions n 'sessions name'
_ci_pop ci-sessions c 'sessions content'
_ci_pop ci-sessions p 'pick project'
_ci_pop ci-sessions a 'pick agent'
_ci_pop ci-sessions g 'pick grade'
_ci_pop ci-sessions O 'pick outcome'
_ci_pop ci-sessions F 'sessions failures'
_ci_pop ci-sessions r 'sessions all'
_ci_exit ci-sessions

# Secretos
_ci_pop ci-secrets l 'secrets all'
_ci_pop ci-secrets p 'secrets pick project'
_ci_pop ci-secrets a 'secrets pick agent'
_ci_pop ci-secrets x 'secrets scan'
_ci_exit ci-secrets

# (El antiguo submenú "Salud por grado" (H ▸ a/b/c/d/f) se eliminó: era
# redundante con `s g` (pick grade). H ahora abre el overview de salud directo.)

# Salir de la tabla root del inspector.
tmux bind-key -T context-inspector q      switch-client -T root
tmux bind-key -T context-inspector Escape switch-client -T root
