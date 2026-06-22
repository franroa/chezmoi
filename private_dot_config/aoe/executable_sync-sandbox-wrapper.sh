#!/usr/bin/env bash
# Copy the custom yas statusline wrapper into EVERY AOE sandbox staging dir.
#
# Why this is needed: AOE mounts a per-profile staging dir ($HOME/.claude/sandbox,
# i.e. ~/.claude/sandbox for `default` and claude-profiles/<ctx>/sandbox for the
# per-context HOMEs) to /root/.claude in the container, and seeds it from
# $HOME/.claude — but it does NOT copy this custom wrapper. The container's
# statusLine command is `$HOME/.claude/yas-docker-wrapper.py` → /root/.claude/...,
# so without the file the statusline silently fails (no statusline). A symlink
# can't be used: it would point at a host path that doesn't exist inside the
# container. So every staging dir needs a REAL copy.
#
# Idempotent. Re-run after editing the host wrapper to push the change to all
# sandboxes (replaces the old manual dual-cp). Copying into a staging dir also
# updates any RUNNING container live, since /root/.claude IS that bind mount.
set -eu

SRC="$HOME/.claude/yas-docker-wrapper.py"
[ -f "$SRC" ] || { echo "no wrapper at $SRC" >&2; exit 1; }

dirs=("$HOME/.claude/sandbox")
for p in "$HOME"/.local/share/claude-profiles/*/sandbox; do
    [ -d "$p" ] && dirs+=("$p")
done

for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    if cp -f "$SRC" "$d/yas-docker-wrapper.py"; then
        echo "synced → $d/yas-docker-wrapper.py"
    fi
done
