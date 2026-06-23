#!/usr/bin/env bash
# gcl-setup.sh — prepare a project for gitlab-ci-local execution
# - init/update git submodules
# - verify .gitlab-ci-local-variables.yml exists
# - check GITLAB_TOKEN available for CI_JOB_TOKEN injection
# - optionally regenerate expanded YAML

set -euo pipefail

CWD="${1:-$PWD}"

# Walk up to find .gitlab-ci.yml root
while [[ "$CWD" != "/" ]]; do
  [[ -f "$CWD/.gitlab-ci.yml" || -f "$CWD/.gitlab-ci.yaml" ]] && break
  CWD="$(dirname "$CWD")"
done
[[ ! -f "$CWD/.gitlab-ci.yml" && ! -f "$CWD/.gitlab-ci.yaml" ]] && {
  echo "❌ No .gitlab-ci.yml found in $1 or any parent"
  read -rp "Press enter to close" _; exit 1
}

echo "── gcl-setup: $CWD ─────────────────────────"

# ── 1. GITLAB_TOKEN check ────────────────────────────────────────────────────
if [[ -z "${GITLAB_TOKEN:-}" ]]; then
  echo "⚠  GITLAB_TOKEN not set — CI_JOB_TOKEN substitution will fail"
  echo "   Set GITLAB_TOKEN in your shell environment (e.g. via 1Password)"
else
  echo "✓ GITLAB_TOKEN present (${GITLAB_TOKEN:0:12}...)"
fi

# ── 2. .gitlab-ci-local-variables.yml ───────────────────────────────────────
vars_file="$CWD/.gitlab-ci-local-variables.yml"
if [[ -f "$vars_file" ]]; then
  echo "✓ $vars_file"
else
  echo "⚠  No .gitlab-ci-local-variables.yml — CI vars like CI_SERVER_FQDN may be missing"
fi

# ── 3. submodules ────────────────────────────────────────────────────────────
if [[ -f "$CWD/.gitmodules" ]]; then
  echo ""
  echo "── Submodules ─────────────────────────────────"
  stale=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^-[[:space:]] ]]; then
      stale=1
      echo "  ⚠  $line (not initialized)"
    elif [[ "$line" =~ ^\+[[:space:]] ]]; then
      echo "  ⚠  $line (newer commit available)"
    else
      echo "  ✓  $line"
    fi
  done < <(git -C "$CWD" submodule status 2>/dev/null)

  if [[ $stale -eq 1 ]]; then
    echo ""
    read -rp "Initialize/update submodules now? [Y/n] " ans
    if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
      echo "▶ git submodule update --init --recursive"
      git -C "$CWD" submodule update --init --recursive
      echo "✓ Submodules ready"
    else
      echo "⚠  Skipped — build may fail if submodules are local projects"
    fi
  fi
else
  echo "✓ No .gitmodules (no submodules)"
fi

# ── 4. list available jobs ───────────────────────────────────────────────────
echo ""
echo "── Available jobs ─────────────────────────────"
(cd "$CWD" && gitlab-ci-local --list 2>&1)

echo ""
echo "── Ready ───────────────────────────────────────"
echo "  Open the pipeline TUI: gctui $CWD     (prefix G v)"
echo "  Run a job:             gitlab-ci-local <job>    (from $CWD)"
echo "  Run first 3 jobs:      gitlab-ci-local get_unique_semversion build:test semgrep-sast"
echo ""
read -rp "Press enter to close" _
