#!/usr/bin/env bash
# prefix-A: New AOE session in ANY folder under $HOME.
#
# Unlike aoen-session.sh (prefix-a), this does NOT ask for a Jira ticket,
# branch prefix or suffix, and does NOT create a git worktree. It just lets
# you pick any directory and choose which Agent of Empires *profile*
# (separate workspace, the `aoe -p` flag) the new session belongs to.

aoe="$(command -v aoe || echo /home/linuxbrew/.linuxbrew/bin/aoe)"

# 1. Pick any folder under $HOME (not just git repos).
dirs=()
while IFS= read -r d; do
    dirs+=("$d")
done < <(
    {
        printf '%s\n' "$HOME"
        find "$HOME" -mindepth 1 -maxdepth 4 -type d \
            -not -path '*/.git' -not -path '*/.git/*' \
            -not -path "$HOME/.cache/*" \
            -not -path "$HOME/.tmux/*" \
            -not -path "$HOME/.oh-my-zsh/*" \
            -not -path "$HOME/.local/*" \
            -not -path "$HOME/.npm/*" \
            -not -path "$HOME/.cargo/*" \
            -not -path "$HOME/build/*" \
            -not -path "$HOME/yay/*" \
            -not -path '*/node_modules/*' \
            2>/dev/null
    } | sort -u
)

selected=$(printf '%s\n' "${dirs[@]}" | fzf \
    --reverse \
    --height=80% \
    --prompt="folder: " \
    --preview="ls -la {}" \
    --preview-window=right:40%)

[ -z "$selected" ] && exit 0

# 2. Choose which aoe profile to use.
#    Read profile names straight from disk instead of parsing `aoe profile list`:
#    the human-readable list format changes between aoe releases, which silently
#    mis-parsed (and even auto-created) bogus profiles. The on-disk layout
#    (profiles/<name>/) is stable. Linux uses $XDG_CONFIG_HOME/agent-of-empires;
#    macOS/Windows use ~/.agent-of-empires.
profiles_dir="${XDG_CONFIG_HOME:-$HOME/.config}/agent-of-empires/profiles"
[ -d "$profiles_dir" ] || profiles_dir="$HOME/.agent-of-empires/profiles"

profiles=()
while IFS= read -r p; do
    [ -n "$p" ] && profiles+=("$p")
done < <(find "$profiles_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)

if [ ${#profiles[@]} -eq 0 ]; then
    profile=""   # fall back to aoe's own default profile
else
    profile=$(printf '%s\n' "${profiles[@]}" | fzf \
        --reverse \
        --height=40% \
        --prompt="profile: ")
    [ -z "$profile" ] && exit 0
fi

# Export so every subsequent `aoe` call targets the chosen profile.
[ -n "$profile" ] && export AGENT_OF_EMPIRES_PROFILE="$profile"

# Run the `aoe` calls with HOME pointed at the matching per-context home so the
# sandbox runs the chosen profile's Claude ACCOUNT. AOE seeds sandbox creds from
# $HOME/.claude/sandbox (NOT from the AOE profile or CLAUDE_CONFIG_DIR), so
# without this every session runs whatever account sits in the real ~/.claude.
# ~/.aoe-homes/<profile> is built by ~/.config/aoe/build-aoe-homes.sh
# (.claude -> claude-profiles/<profile>). We set HOME ONLY for the aoe subprocesses
# (via this prefix) — NOT globally — so tmux/switch-client keep the real HOME.
# Profiles with no context home (e.g. default/main) get an empty prefix.
aoe_env=()
if [ -n "$profile" ] && [ -d "$HOME/.aoe-homes/$profile" ]; then
    aoe_env=(env "HOME=$HOME/.aoe-homes/$profile")
fi

cd "$selected" || exit 1

sessions_before=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

# 3. Create a plain session in this folder (no worktree, no branch).
#    Name the session after the folder itself (basename, not the full path).
folder_name="${selected##*/}"
"${aoe_env[@]}" "$aoe" add . -t "$folder_name" || exit 1

# 4. Start the most recently created aoe session.
aoe_session_id=$("${aoe_env[@]}" "$aoe" list --json 2>/dev/null \
    | jq -r 'sort_by(.created_at) | last | .id')

[ -z "$aoe_session_id" ] && exit 1

"${aoe_env[@]}" "$aoe" session start "$aoe_session_id" 2>/dev/null

# 5. Switch the calling client to the new tmux session.
new_tmux_session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null \
    | grep -vxF "$sessions_before" | head -1)

[ -n "$new_tmux_session" ] \
    && tmux switch-client -c "$TMUX_PARENT_CLIENT" -t "$new_tmux_session"
