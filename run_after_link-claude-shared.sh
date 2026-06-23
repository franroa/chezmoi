#!/usr/bin/env bash
# Share Claude Code config across all claude-profile profiles by symlinking each
# profile's entries to the canonical ~/.claude store (which is also the AOE
# sandbox hub that AOE reads from).
#
# POLICY: default = SHARE. Every entry in ~/.claude is symlinked into every
# profile EXCEPT the ones is_isolated() matches below. So ALL config — settings,
# settings.local, CLAUDE.md, agents, commands, plugins (incl. marketplaces:
# known_marketplaces.json / installed_plugins.json / marketplaces/), skills,
# hooks, rules, projects, history, the yas wrapper, AND anything added to
# ~/.claude later — is identical across profiles with no edit to this script.
# New files inside already-symlinked dirs are shared instantly (no rerun needed).
#
# Isolated (kept per-profile): the ACCOUNT (.credentials.json + the .claude.json
# identity/cache) — the ONLY things that should differ between profiles — plus
# machine/runtime state that must NOT be shared between concurrently-running
# profiles (sessions, daemon, caches, logs, locks, ...). If a NEW *runtime* (not
# config) entry ever appears at the top level of ~/.claude, add it to
# is_isolated(); everything else is shared by default, by design.
#
# Idempotent: re-running only fixes drift; correct links are skipped. Any real
# file/dir it replaces is moved to ~/.local/share/claude-profiles/.backup-<ts>/.
set -eu

CANON="$HOME/.claude"
PROFILES_DIR="$HOME/.local/share/claude-profiles"

[ -d "$PROFILES_DIR" ] || exit 0
[ -d "$CANON" ]        || exit 0

# Entries that stay PER-PROFILE (never symlinked to canonical).
is_isolated() {
    case "$1" in
        # --- account / credentials: the ONLY things that should differ ---
        .credentials.json|.claude.json) return 0 ;;
        # --- per-profile runtime state, caches, locks (must not be shared) ---
        sessions|session-env|sandbox|jobs|tasks|plans|cache|backups|\
        file-history|paste-cache|shell-snapshots|statusline-output|telemetry|\
        downloads|__pycache__) return 0 ;;
        daemon|daemon.lock|daemon.log|daemon.status.json) return 0 ;;
        # --- per-profile bookkeeping / machine-local state ---
        .last-cleanup|.last-update-result.json|mcp-needs-auth-cache.json|\
        policy-limits.json|remote-settings.json|.company-seeded|\
        HOST-LOGIN-STATUS.md|yas-last-prompt.json) return 0 ;;
        # --- logs and backups (any) ---
        *.log|*.bak|*.bak-*) return 0 ;;
        # --- never touch VCS / self-referential entries ---
        .git|.|..) return 0 ;;
        *) return 1 ;;
    esac
}

# Ensure the essential shared config exists in canonical so a fresh hub is valid.
mkdir -p "$CANON/agents" "$CANON/commands" "$CANON/skills" "$CANON/plugins" \
         "$CANON/projects" "$CANON/hooks" "$CANON/rules"
[ -e "$CANON/CLAUDE.md" ]           || : > "$CANON/CLAUDE.md"
[ -e "$CANON/settings.json" ]       || echo '{}' > "$CANON/settings.json"
[ -e "$CANON/settings.local.json" ] || echo '{}' > "$CANON/settings.local.json"
[ -e "$CANON/history.jsonl" ]       || : > "$CANON/history.jsonl"

shopt -s dotglob nullglob

ts=$(date +%Y%m%dT%H%M%S)
for prof in "$PROFILES_DIR"/*/; do
    [ -d "$prof" ] || continue
    name=$(basename "$prof")
    case "$name" in .backup-*) continue ;; esac   # skip our own backup dirs

    for path in "$CANON"/*; do
        item=$(basename "$path")
        is_isolated "$item" && continue

        target="$CANON/$item"
        link="${prof%/}/$item"

        # Already the correct symlink -> nothing to do.
        if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
            continue
        fi
        # Back up any real file/dir or stale link before replacing.
        if [ -e "$link" ] || [ -L "$link" ]; then
            bk="$PROFILES_DIR/.backup-$ts/$name"
            mkdir -p "$bk"
            mv "$link" "$bk/$item"
        fi
        ln -s "$target" "$link"
    done
done
