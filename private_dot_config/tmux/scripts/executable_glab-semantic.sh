#!/usr/bin/env bash
# AI-powered semantic code search (natural language) in the GitLab project of
# the current directory, via `glab search semantic`. Unlike glab-search.sh this
# is per-project, not group-wide, and needs semantic indexing on the project.
#
# Usage: glab-semantic.sh <query> [path]   (run from inside a clone; [path]
#        restricts the search to files under that directory, e.g. app/services/)
set -uo pipefail

query="${1:-}"
path="${2:-}"

if [ -z "$query" ]; then
  echo "❌ no search query given"
  read -r -p "Press enter to close" _
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ not inside a git repository: $PWD"
  read -r -p "Press enter to close" _
  exit 0
fi

args=(-q "$query" --limit 20)
[ -n "$path" ] && args+=(-d "$path")

echo "🧠 semantic search '${query}'${path:+ under ${path}} in $(git remote get-url origin 2>/dev/null) ..."
glab search semantic "${args[@]}" 2>&1 | less -R
