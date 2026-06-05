#!/usr/bin/env bash
# Sessionizer: fzf project dirs → create or switch tmux session

SEARCH_DIRS=(
    "$HOME/Projects"
    "$HOME/agent-of-empires"
    "$HOME/ComfyUI"
    "$HOME/hyprfocus"
    "$HOME/dotfiles"
    "$HOME/.dotfiles"
    "$HOME/.config/nvim"
)

# Collect: explicit dirs + 1-level children of ~/Projects
dirs=()
for d in "${SEARCH_DIRS[@]}"; do
    [ -d "$d" ] && dirs+=("$d")
done
while IFS= read -r d; do
    dirs+=("$d")
done < <(find "$HOME/Projects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

selected=$(printf '%s\n' "${dirs[@]}" | sort -u | fzf \
    --reverse \
    --height=40% \
    --prompt="session: " \
    --preview="ls {}" \
    --preview-window=right:40%)

[ -z "$selected" ] && exit 0

session_name=$(basename "$selected" | tr ' .' '_')

if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -ds "$session_name" -c "$selected"
fi

tmux switch-client -t "$session_name"
