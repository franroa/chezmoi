#!/usr/bin/env bash
# Open a GitLab resource in the browser via glab, surfacing the *real* error
# instead of always blaming the repository.
#
# Usage: glab-open.sh <repo|pipeline|pipelines-list> <pane_current_path>
set -uo pipefail

mode="${1:-repo}"
path="${2:-$PWD}"

cd "$path" 2>/dev/null || {
  tmux display-message "❌ Path not accessible: $path"
  exit 0
}

# Distinguish the genuine "not a repo" case from a glab/browser failure.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  tmux display-message "❌ Not a git repository"
  exit 0
fi

case "$mode" in
  repo)
    if ! out="$(glab repo view --web 2>&1)"; then
      msg="$(printf '%s\n' "$out" \
        | sed -E 's/\x1b\[[0-9;]*[mGKH]//g' \
        | grep -v '^[[:space:]]*$' \
        | tail -n1 \
        | sed -E 's/^[[:space:]]+//')"
      [ -z "$msg" ] && msg="glab repo view --web failed"
      tmux display-message "❌ glab: $msg"
      exit 0
    fi
    ;;
  pipeline)
    # ci view --web requires a TTY; fetch the pipeline URL from ci status JSON.
    tmux display-message " opening pipeline…"
    if ! out="$(glab ci status --output json 2>&1)"; then
      msg="$(printf '%s\n' "$out" \
        | sed -E 's/\x1b\[[0-9;]*[mGKH]//g' \
        | grep -v '^[[:space:]]*$' \
        | tail -n1 \
        | sed -E 's/^[[:space:]]+//')"
      [ -z "$msg" ] && msg="glab ci status failed"
      tmux display-message "❌ glab: $msg"
      exit 0
    fi
    # Use the top-level pipeline.web_url (the .../-/pipelines/<id> page), NOT the
    # first job/commit web_url that a naive grep would pick up.
    url="$(printf '%s' "$out" | jq -r '.pipeline.web_url // empty' 2>/dev/null)"
    if [ -z "$url" ]; then
      # Fallback: query the API for the latest pipeline on the current branch.
      b="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
      url="$(glab api "projects/:id/pipelines?ref=${b}&per_page=1" 2>/dev/null \
        | jq -r '.[0].web_url // empty' 2>/dev/null)"
    fi
    if [ -z "$url" ]; then
      tmux display-message "❌ glab: no pipeline found for this branch"
      exit 0
    fi
    # Foreground so we can detect a failed launch (no handler / dead display)
    # instead of swallowing it in a backgrounded process.
    if ! xdg-open "$url" >/dev/null 2>&1; then
      tmux display-message "❌ could not open browser: $url"
      exit 0
    fi
    tmux display-message " $url"
    ;;
  pipelines-list)
    # Open the repo's /-/pipelines page in browser.
    if ! out="$(glab repo view --web 2>&1)"; then
      msg="$(printf '%s\n' "$out" \
        | sed -E 's/\x1b\[[0-9;]*[mGKH]//g' \
        | grep -v '^[[:space:]]*$' \
        | tail -n1 \
        | sed -E 's/^[[:space:]]+//')"
      [ -z "$msg" ] && msg="glab repo view --web failed"
      tmux display-message "❌ glab: $msg"
      exit 0
    fi
    # Derive pipelines URL from remote.
    remote_url="$(git remote get-url origin 2>/dev/null)"
    # Normalise SSH and HTTPS forms to a web URL.
    web_url="$(printf '%s\n' "$remote_url" \
      | sed -E 's|git@([^:]+):|https://\1/|; s|\.git$||')"
    if [ -z "$web_url" ]; then
      tmux display-message "❌ glab: could not determine repo URL"
      exit 0
    fi
    xdg-open "${web_url}/-/pipelines" >/dev/null 2>&1 &
    ;;
  *)
    tmux display-message "❌ Unknown mode: $mode"
    exit 1
    ;;
esac
