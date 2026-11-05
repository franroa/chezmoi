#!/usr/bin/env bash
# run-shell target for the which-key "Open repo by slug" prompt. Arg: <slug>.
# Resolves the slug to a project you are a member of (exact path match) and
# opens its web page in the browser.
set -uo pipefail

slug="$(printf '%s' "$*" | tr -d '[:space:]')"
if [ -z "$slug" ]; then
  tmux display-message "❌ empty repo slug"
  exit 0
fi

url="$(glab api "projects?search=${slug}&membership=true&per_page=100" 2>/dev/null \
  | jq -r --arg s "$slug" '[.[] | select(.path == $s)][0].web_url // empty' 2>/dev/null)"

if [ -z "$url" ]; then
  tmux display-message "❌ no project with slug '$slug' (membership)"
  exit 0
fi

if ! xdg-open "$url" >/dev/null 2>&1; then
  tmux display-message "❌ could not open browser: $url"
  exit 0
fi
tmux display-message " $url"
