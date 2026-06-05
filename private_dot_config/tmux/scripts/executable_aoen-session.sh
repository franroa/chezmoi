#!/usr/bin/env bash
repos=()
while IFS= read -r r; do
    repos+=("$r")
done < <(find "$HOME" -maxdepth 4 -name ".git" -type d \
    -not -path "$HOME/.cache/*" \
    -not -path "$HOME/.tmux/*" \
    -not -path "$HOME/.oh-my-zsh/*" \
    -not -path "$HOME/build/*" \
    -not -path "$HOME/yay/*" \
    -not -path "$HOME/swappy/*" \
    -not -path "$HOME/Ubuntu-Hyprland*" \
    -not -path "$HOME/.icons/*" \
    -not -path "$HOME/.config/minimalvim*" \
    2>/dev/null | sed 's|/.git$||' | sort -u)

selected=$(printf '%s\n' "${repos[@]}" | fzf \
    --reverse \
    --height=80% \
    --prompt="repo: " \
    --preview="ls {}" \
    --preview-window=right:40%)

[ -z "$selected" ] && exit 0

cd "$selected" || exit 1

sessions_before=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

fish -c 'aoen'

# get most recently created aoe session id
aoe_session_id=$(aoe list --json 2>/dev/null \
    | jq -r 'sort_by(.created_at) | last | .id')

[ -z "$aoe_session_id" ] && exit 1

# start the tmux process for this aoe session
aoe session start "$aoe_session_id" 2>/dev/null

# find the new tmux session
new_tmux_session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null \
    | grep -vxF "$sessions_before" | head -1)

[ -n "$new_tmux_session" ] \
    && tmux switch-client -c "$TMUX_PARENT_CLIENT" -t "$new_tmux_session"
