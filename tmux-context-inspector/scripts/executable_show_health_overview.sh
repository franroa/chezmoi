#!/usr/bin/env bash
# Salud e inteligencia — OVERVIEW de todas las sesiones (tecla H).
#
# Fuente: agentsview `health` (lista de sesiones recientes con grade/outcome) +
# `stats` (analítica del workspace en ventana 28d). Es la contraparte global de
# la vista h (sesión actual). Para navegar/abrir sesiones por grado usa s g.
#
# Doc: https://www.agentsview.io/session-intelligence/#agentsview-health
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_capture.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_recommend.sh"

out="$(mktemp)"

if ci_have_agentsview; then
    {
        echo "═══ Salud e inteligencia — overview (agentsview) ═══"
        echo
        echo "— Sesiones recientes (grade · outcome)"
        echo
        agentsview health --limit 25 2>&1
        echo
        echo "— Stats del workspace (ventana 28d)"
        echo
        agentsview stats 2>&1
        ci_workspace_recommendations
        echo
        echo "Salud de la sesión actual: vista h  ·  navegar por grado: s g  ·  proyectos: r"
    } > "$out"
else
    {
        echo "═══ Salud e inteligencia — overview ═══"
        echo
        echo "agentsview no está instalado."
        echo "Instálalo para el overview de grade/outcome y los stats del workspace."
    } > "$out"
fi

ci_popup_file "$out"
