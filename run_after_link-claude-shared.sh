#!/usr/bin/env bash
# Share Claude Code config + history across all claude-profile profiles by
# symlinking each profile's shared entries to the canonical ~/.claude store
# (which is also the AOE sandbox hub that AOE reads from).
#
# Shared (symlinked -> ~/.claude): settings.json, CLAUDE.md, agents, commands,
#   plugins, skills, projects, history.jsonl
# Isolated (left untouched per profile): .credentials.json, .claude.json,
#   sessions, session-env, caches, settings.local.json, etc.
#
# Idempotent: re-running only fixes drift; correct links are skipped. Any real
# file/dir it replaces is moved to ~/.local/share/claude-profiles/.backup-<ts>/.
set -eu

CANON="$HOME/.claude"
PROFILES_DIR="$HOME/.local/share/claude-profiles"
SHARED="settings.json CLAUDE.md agents commands plugins skills projects history.jsonl"

[ -d "$PROFILES_DIR" ] || exit 0

# Ensure canonical shared entries exist so profile symlinks never dangle.
mkdir -p "$CANON/agents" "$CANON/commands" "$CANON/skills" "$CANON/plugins" "$CANON/projects"
[ -e "$CANON/CLAUDE.md" ]     || : > "$CANON/CLAUDE.md"
[ -e "$CANON/settings.json" ] || echo '{}' > "$CANON/settings.json"
[ -e "$CANON/history.jsonl" ] || : > "$CANON/history.jsonl"

ts=$(date +%Y%m%dT%H%M%S)
for prof in "$PROFILES_DIR"/*/; do
    [ -d "$prof" ] || continue
    name=$(basename "$prof")
    for item in $SHARED; do
        target="$CANON/$item"
        link="${prof%/}/$item"
        [ -e "$target" ] || continue
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
