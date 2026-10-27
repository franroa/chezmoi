#!/usr/bin/env bash
# Group-wide open MRs involving me, for the which-key Overseer menu.
#
# Usage: overseer-mrs.sh <reviewer|author> [group]
set -uo pipefail

role="${1:-reviewer}"
group="${2:-technosylva}"

case "$role" in
  reviewer) echo "👀 MRs waiting on my review in ${group} ..." ;;
  author) echo "📝 my open MRs in ${group} ..." ;;
  *)
    echo "❌ unknown role '${role}' (expected reviewer|author)"
    read -r -p "Press enter to close" _
    exit 0
    ;;
esac

glab mr list -g "$group" "--${role}=@me" --per-page 100 2>&1
echo
read -r -p "Press enter to close" _
