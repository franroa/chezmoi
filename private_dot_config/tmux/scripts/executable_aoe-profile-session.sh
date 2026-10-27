#!/usr/bin/env bash
# prefix-T: New AOE session in a fresh git worktree of any repo under $HOME.
#
# Unlike aoen-session.sh (prefix-a), this does NOT ask for a Jira ticket or
# branch name: pick a repo root and which Agent of Empires *profile* (separate
# workspace, the `aoe -p` flag) the new session belongs to. Every session gets
# its own worktree on a fresh wip/<hash> branch, so the same repo can have any
# number of sessions open.
# The worktree is the aoe session's project_path, which workspace-dir.sh
# resolves for every pane (claude, nvim, lazygit, k9s, shell).

aoe="$(command -v aoe || echo /home/linuxbrew/.linuxbrew/bin/aoe)"
fd="$(command -v fd || command -v fdfind)"

# 1. Pick a git repo root. Only `.git` *directories* count: linked worktrees
#    (aoe's .aoe-worktrees/*) have a `.git` file, so they never show up.
#    Nested repos (vendored clones, plugin checkouts, .gitlab-ci-local builds)
#    are dropped: with paths sorted as "<path>/", a child always directly
#    follows its root. fzf runs previews with $SHELL (fish here), hence
#    --with-shell for the bash syntax below.
repos=()
while IFS= read -r r; do
    repos+=("$r")
done < <(
    "$fd" -H -I -t d --prune '^\.git$' "$HOME" --max-depth 7 \
        -E .cache -E .local -E .tmux -E .npm -E .cargo -E .oh-my-zsh \
        -E .aisbx -E .copilot -E .opencode -E .ori -E .icons \
        -E node_modules -E .aoe-worktrees -E .aoe-workspaces \
        -E build -E yay -E .config/tmux/plugins \
        2>/dev/null \
        | sed 's|/\.git/\?$|/|' | LC_ALL=C sort -u \
        | awk 'root != "" && index($0, root) == 1 { next } { root = $0; print }' \
        | sed "s|/\$||; s|^$HOME|~|"
)

selected=$(printf '%s\n' "${repos[@]}" | fzf \
    --reverse \
    --height=80% \
    --prompt="repo: " \
    --with-shell='bash -c' \
    --preview="d={}; d=\"\${d/#\\~/$HOME}\"; git -C \"\$d\" worktree list; echo; ls \"\$d\"" \
    --preview-window=right:50%)

[ -z "$selected" ] && exit 0
repo="${selected/#\~/$HOME}"

# 2. Throwaway branch for the new worktree: wip/<random hash>, branched off the
#    repo's default branch (aoe's --new-branch default). The agent renames it
#    once it knows what the work is, so any number of worktrees can be cut from
#    main without naming anything up front.
while :; do
    hash=$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')
    branch="wip/$hash"
    git -C "$repo" show-ref --quiet "refs/heads/$branch" || break
done

# 3. Choose which aoe profile to use.
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

# Export so every subsequent `aoe` call targets the chosen profile. This also
# selects the profile's Claude ACCOUNT: a profile carries its credentials via its
# own profiles/<name>/config.toml `environment = ["CLAUDE_CONFIG_DIR=..."]`, which
# AOE injects onto the host agent launch command (CLAUDE_CONFIG_DIR wins over
# $HOME). So no HOME hack is needed here anymore — the old `env HOME=...` wrapper
# was removed. The `default` profile sets no override -> real ~/.claude (work).
# See memory: aoe-percontext-credentials / AOE issue #2302 comment 4768511171.
[ -n "$profile" ] && export AGENT_OF_EMPIRES_PROFILE="$profile"

cd "$repo" || exit 1

sessions_before=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

# 4. Create the session in a new worktree (aoe's [worktree] path_template,
#    i.e. <repo>/.aoe-worktrees/<branch>). Titled <repo>-<hash> rather than
#    after the branch, since the branch gets renamed later.
if ! "$aoe" add . -t "${repo##*/}-$hash" -w "$branch" -b; then
    read -rp "aoe add failed — press enter to close" _
    exit 1
fi

# 5. Start the most recently created aoe session.
session=$("$aoe" list --json 2>/dev/null | jq -c 'sort_by(.created_at) | last')
aoe_session_id=$(jq -r '.id // empty' <<<"$session")
worktree=$(jq -r '.path // empty' <<<"$session")

[ -z "$aoe_session_id" ] && exit 1

# .env is gitignored, so a new worktree doesn't get it; without it docker
# compose & co. fall back to wrong defaults. Copy it before any pane starts.
[ -f "$repo/.env" ] && [ -d "$worktree" ] && [ ! -e "$worktree/.env" ] \
    && cp "$repo/.env" "$worktree/.env"

"$aoe" session start "$aoe_session_id" 2>/dev/null

# 6. Switch the calling client to the new tmux session.
new_tmux_session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null \
    | grep -vxF "$sessions_before" | head -1)

[ -n "$new_tmux_session" ] \
    && tmux switch-client -c "$TMUX_PARENT_CLIENT" -t "$new_tmux_session"
