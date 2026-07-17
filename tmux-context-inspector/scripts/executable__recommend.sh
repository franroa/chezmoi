#!/usr/bin/env bash
#
# _recommend.sh — Recommendations synthesis shared by show_health.sh (tecla h,
# sesión actual) y show_health_overview.sh (tecla H, workspace). Replica el
# orden de prioridad usado por las skills session-analytics / usage-analytics
# de Claude Code: secrets > señal de fallo > friccion > insights obsoleto >
# anomalia vs baseline > aviso del timeline. Grounded — sólo recomienda lo que
# los datos realmente muestran, nunca rellena para llegar a un número fijo.
#
# Sourced by show_health.sh / show_health_overview.sh (después de _capture.sh,
# que ya trae _lib.sh con jq/agentsview helpers).

# ci_session_recommendations <id> <health_json> <timeline_text>
#   health_json:   salida cruda de `agentsview health <id> --json` (puede ser vacía)
#   timeline_text: salida cruda de av_model_timeline.sh (para el check de ⚠)
# Máximo 2 líneas, la más severa primero. Sin salida si nada aplica.
ci_session_recommendations() {
    local id="$1" health_json="$2" timeline_text="$3"
    local recs=()

    if [ -n "$health_json" ]; then
        local secrets grade streak
        secrets="$(jq -r '.secret_leak_count // 0' <<<"$health_json" 2>/dev/null)"
        grade="$(jq -r '.health_grade // ""' <<<"$health_json" 2>/dev/null)"
        streak="$(jq -r '.final_failure_streak // 0' <<<"$health_json" 2>/dev/null)"

        if [ "${secrets:-0}" -gt 0 ] 2>/dev/null; then
            recs+=("$secrets secreto(s) detectado(s) en esta sesión — confirma que la credencial está rotada/expirada antes de darla por cerrada.")
        fi
        if [ -n "$grade" ] && [[ "$grade" =~ ^[CDF]$ ]]; then
            recs+=("Grade $grade — revisa qué pasó cerca del final de la sesión, algo no salió limpio.")
        elif [ "${streak:-0}" -gt 0 ] 2>/dev/null; then
            recs+=("Racha de $streak fallo(s) al final de la sesión — revisa las últimas tool calls antes de cerrarla.")
        fi
    fi

    local facet="$HOME/.claude/usage-data/facets/$id.json"
    if [ -f "$facet" ]; then
        local outcome friction
        outcome="$(jq -r '.outcome // ""' "$facet" 2>/dev/null)"
        friction="$(jq -r '.friction_detail // ""' "$facet" 2>/dev/null)"
        if [ -n "$friction" ]; then
            recs+=("Fricción anotada por /insights: \"$friction\"")
        elif [ -n "$outcome" ] && [ "$outcome" != "fully_achieved" ]; then
            recs+=("Outcome juzgado por /insights: $outcome (no fully_achieved) — vale la pena revisarlo antes de cerrar.")
        fi
    else
        local newest_facet
        newest_facet="$(ls -t "$HOME/.claude/usage-data/facets/"*.json 2>/dev/null | head -n1)"
        [ -z "$newest_facet" ] && recs+=("/insights nunca se ha ejecutado — ninguna sesión tiene datos de Goal/Outcome/friction todavía.")
    fi

    if [ -n "$health_json" ]; then
        local churn baseline_json avg_churn
        churn="$(jq -r '.edit_churn_count // 0' <<<"$health_json" 2>/dev/null)"
        baseline_json="$(agentsview stats --format json --since 28d 2>/dev/null)"
        if [ -n "$baseline_json" ]; then
            avg_churn="$(jq -r '.outcomes.avg_edit_churn // empty' <<<"$baseline_json" 2>/dev/null)"
            if [ -n "${avg_churn:-}" ] && [ -n "${churn:-}" ] \
                && awk -v c="$churn" -v a="$avg_churn" 'BEGIN{exit !(a>0.1 && c>a*2)}' 2>/dev/null; then
                local avg_churn_fmt
                avg_churn_fmt="$(awk -v a="$avg_churn" 'BEGIN{printf "%.2f", a}')"
                recs+=("Edit churn ($churn) muy por encima de la media 28d ($avg_churn_fmt) — considera planear más antes de implementar.")
            fi
        fi
    fi

    if [[ "$timeline_text" == *"⚠"* ]]; then
        recs+=("El timeline de arriba marcó un tramo con modelo caro fuera de plan mode — confirma que fue intencional.")
    fi

    [ "${#recs[@]}" -eq 0 ] && return 0

    echo
    echo "— Recommendations —"
    local i=0 r
    for r in "${recs[@]}"; do
        i=$((i + 1))
        [ "$i" -gt 2 ] && break
        echo "  $i. $r"
    done
}

# ci_workspace_recommendations
#   Sin argumentos — hace sus propias llamadas a agentsview (stats/usage
#   daily/secrets list) igual que la skill usage-analytics. Máximo 4 líneas.
ci_workspace_recommendations() {
    local recs=() since_date
    since_date="$(date -u -d '28 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-28d +%Y-%m-%d)"

    # 1. Secrets en la ventana de 28d — siempre la prioridad más alta si hay.
    local secrets_json count
    secrets_json="$(agentsview secrets list --format json --date-from "$since_date" 2>/dev/null)"
    count="$(jq -r '(.findings // []) | length' <<<"$secrets_json" 2>/dev/null)"
    if [ -n "${count:-}" ] && [ "$count" -gt 0 ] 2>/dev/null; then
        local rule proj
        rule="$(jq -r '[.findings[].rule_name] | group_by(.) | max_by(length) | .[0]' <<<"$secrets_json" 2>/dev/null)"
        proj="$(jq -r '[.findings[].project] | unique | join(", ")' <<<"$secrets_json" 2>/dev/null)"
        recs+=("$count secreto(s) en los últimos 28d (mayoría $rule) en: $proj — confirma que están rotados/expirados.")
    fi

    # 2. Tendencia de coste, primera mitad vs segunda mitad de la ventana.
    local daily_json trend
    daily_json="$(agentsview usage daily --since "$since_date" --json 2>/dev/null)"
    if [ -n "$daily_json" ]; then
        trend="$(jq -r '
            .daily as $d
            | ($d | length) as $n
            | ($n / 2 | floor) as $half
            | ($d[0:$half] | map(.totalCost) | add // 0) as $first
            | ($d[$half:$n] | map(.totalCost) | add // 0) as $second
            | if $first > 0 and (($second - $first) / $first) > 0.4 then "subiendo:\($first|round):\($second|round)"
              elif $first > 0 and (($first - $second) / $first) > 0.4 then "bajando:\($first|round):\($second|round)"
              else empty end
        ' <<<"$daily_json" 2>/dev/null)"
        if [ -n "${trend:-}" ]; then
            local dir first second
            IFS=: read -r dir first second <<<"$trend"
            recs+=("Coste $dir semana contra semana (\$$first -> \$$second) — confirma que corresponde a trabajo genuinamente más difícil.")
        fi
    fi

    # 3. Grade tail (C/D/F) en la ventana de 28d.
    local stats_json tail
    stats_json="$(agentsview stats --format json --since 28d 2>/dev/null)"
    if [ -n "$stats_json" ]; then
        tail="$(jq -r '(.outcomes.grade_distribution.C // 0) + (.outcomes.grade_distribution.D // 0) + (.outcomes.grade_distribution.F // 0)' <<<"$stats_json" 2>/dev/null)"
        if [ -n "${tail:-}" ] && [ "$tail" -gt 0 ] 2>/dev/null; then
            recs+=("$tail sesión(es) con grade C/D/F en los últimos 28d — vale la pena revisar qué falló en esas.")
        fi
    fi

    # 4. /insights nunca ejecutado, o obsoleto.
    local newest_facet
    newest_facet="$(ls -t "$HOME/.claude/usage-data/facets/"*.json 2>/dev/null | head -n1)"
    if [ -z "$newest_facet" ]; then
        recs+=("/insights nunca se ha ejecutado — no hay datos de Outcomes/Satisfaction/Friction todavía.")
    else
        local now mtime age_h
        now="$(date +%s)"
        mtime="$(stat -c %Y "$newest_facet" 2>/dev/null || stat -f %m "$newest_facet")"
        age_h=$(( (now - mtime) / 3600 ))
        [ "$age_h" -gt 4 ] && recs+=("/insights se ejecutó por última vez hace ${age_h}h — vuelve a correrlo para refrescar Outcomes/Satisfaction/Friction.")
    fi

    [ "${#recs[@]}" -eq 0 ] && return 0

    echo
    echo "— Recommendations —"
    local i=0 r
    for r in "${recs[@]}"; do
        i=$((i + 1))
        [ "$i" -gt 4 ] && break
        echo "  $i. $r"
    done
}
