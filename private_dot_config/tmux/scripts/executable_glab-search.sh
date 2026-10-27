#!/usr/bin/env bash
# GitLab-wide code search across the whole group, via the GitLab search API
# (approach shared by Luis in Slack: `groups/<group>/search?scope=blobs`).
# Regular `glab` has no group-wide code search, so this hits the API directly
# and resolves numeric project_ids back to `namespace/repo` for readability.
#
# Usage: glab-search.sh <query> [group]
set -uo pipefail

query="${1:-}"
group="${2:-technosylva}"

if [ -z "$query" ]; then
  echo "❌ no search query given"
  read -r -p "Press enter to close" _
  exit 0
fi

echo "🔍 searching '${query}' in group ${group} ..."
results="$(glab api --method GET --paginate "groups/${group}/search?scope=blobs&search=${query}" 2>&1)"
if [ $? -ne 0 ]; then
  echo "❌ glab api search failed:"
  printf '%s\n' "$results" | tail -n5
  read -r -p "Press enter to close" _
  exit 0
fi

hits="$(printf '%s' "$results" | jq -r '.[] | "\(.project_id)\t\(.path):\(.startline)\t\(.data)"' 2>/dev/null)"
if [ -z "$hits" ]; then
  echo "No matches for '${query}' in group ${group}"
  read -r -p "Press enter to close" _
  exit 0
fi

# translate project_id -> namespace/repo once per id, not once per hit
declare -A repo_names
while IFS= read -r id; do
  [ -z "$id" ] && continue
  repo_names["$id"]="$(glab api "projects/$id" 2>/dev/null | jq -r '.path_with_namespace // empty')"
done < <(printf '%s\n' "$hits" | cut -f1 | sort -u)

printf '%s\n' "$hits" | while IFS=$'\t' read -r id loc data; do
  echo "${repo_names[$id]:-$id}  ${loc}"
  echo "    ${data}"
done

read -r -p "Press enter to close" _
