#!/usr/bin/env bash
# Build per-context HOMEs so AOE sandbox sessions run the matching Claude ACCOUNT.
# AOE derives sandbox credentials from $HOME/.claude/sandbox (NOT from the AOE
# profile / CLAUDE_CONFIG_DIR), so the only way to pick the account is to point
# HOME at a home whose .claude is the desired profile. Each ~/.aoe-homes/<ctx>
# mirrors the real $HOME via symlinks, EXCEPT the account-specific files
# (.claude dir and .claude.json) which point at claude-profiles/<ctx>.
# Idempotent: safe to re-run (e.g. after new dotfiles appear in $HOME).
#
# NOTE: the `default` AOE profile needs NO per-context HOME — it uses the real
# $HOME/.claude (= the work/Technosylva account, the hub). Only non-default
# accounts (personal) need a mirror home here.
set -euo pipefail
REAL_HOME="${HOME}"
PROFILES_BASE="$REAL_HOME/.local/share/claude-profiles"
CONTEXTS=("$@"); [ ${#CONTEXTS[@]} -eq 0 ] && CONTEXTS=(personal)
for ctx in "${CONTEXTS[@]}"; do
    cp_dir="$PROFILES_BASE/$ctx"
    if [ ! -d "$cp_dir" ]; then echo "skip '$ctx': no claude-profile dir at $cp_dir"; continue; fi
    ch="$REAL_HOME/.aoe-homes/$ctx"
    mkdir -p "$ch"
    # mirror every top-level entry of the real HOME (dotfiles + the rest)…
    for entry in "$REAL_HOME"/.[!.]* "$REAL_HOME"/*; do
        [ -e "$entry" ] || continue
        name="$(basename "$entry")"
        # …EXCEPT account-specific files + the homes dir itself (avoid recursion)
        case "$name" in .claude|.claude.json|.aoe-homes) continue ;; esac
        ln -sfn "$entry" "$ch/$name"
    done
    # account-specific store + identity, from this profile
    ln -sfn "$cp_dir"              "$ch/.claude"
    ln -sfn "$cp_dir/.claude.json" "$ch/.claude.json"
    echo "built $ch  (.claude + .claude.json -> $ctx profile)"
done
