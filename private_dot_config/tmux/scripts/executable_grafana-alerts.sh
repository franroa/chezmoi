#!/usr/bin/env bash
# Currently firing (active, not silenced/inhibited) Grafana-managed alerts.
# Needs $GRAFANA_TOKEN in the tmux global environment.
#
# Usage: grafana-alerts.sh [grafana-url]
set -uo pipefail

url="${1:-https://grafana.technosylva.io}"

if [ -z "${GRAFANA_TOKEN:-}" ]; then
  echo "❌ GRAFANA_TOKEN is not set"
  read -r -p "Press enter to close" _
  exit 0
fi

echo "🚨 firing alerts on ${url} ..."
body="$(curl -s -m 20 -w '\n%{http_code}' -H "Authorization: Bearer $GRAFANA_TOKEN" \
  "${url}/api/alertmanager/grafana/api/v2/alerts?active=true&silenced=false&inhibited=false")"
code="${body##*$'\n'}"
body="${body%$'\n'*}"

if [ "$code" != "200" ]; then
  echo "❌ Grafana returned HTTP ${code}:"
  printf '%s\n' "$body" | head -n5
  [ "$code" = "401" ] && echo "   (GRAFANA_TOKEN is invalid or expired)"
  read -r -p "Press enter to close" _
  exit 0
fi

printf '%s' "$body" | jq -r '
  if length == 0 then "✅ nothing firing" else
    (["SINCE", "SEVERITY", "NAMESPACE", "ALERT"] | @tsv),
    (sort_by(.startsAt) | reverse | .[] |
      [(.startsAt | .[0:16]), (.labels.severity // "-"), (.labels.namespace // "-"), .labels.alertname] | @tsv)
  end' | column -t -s $'\t' | less -R
