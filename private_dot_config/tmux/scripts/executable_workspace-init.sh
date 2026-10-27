#!/usr/bin/env bash
# after-new-session: first pane = claude, plus nvim, lazygit, k9s and shell panes; claude zoomed.
# The hook gets no session context when aoe creates the session (#{session_id} and
# #{hook_session} expand empty), so target the newest session instead.
sid=$(tmux list-sessions -F '#{session_created} #{session_id}' | sort -n | tail -1 | cut -d' ' -f2)
[ -n "$sid" ] || exit 1
claude=$(tmux list-panes -t "$sid" -F '#{pane_id}' | head -1)
# aoe creates the session in $HOME and cds the claude pane later, so neither
# session_path nor pane_current_path is reliable here: resolve the project dir
# from aoe's sessions.json (cached in @workspace_dir, shared with workspace-focus).
dir=$(~/.config/tmux/scripts/workspace-dir.sh -t "$sid")
# cluster first, so the panes split below inherit KUBECONFIG/K8S_CLUSTER
~/.config/tmux/scripts/kube-switch.sh -t "$sid" >/dev/null 2>&1
tmux set-option -p -t "$claude" @role claude
nvim=$(tmux split-window -h -d -P -F '#{pane_id}' -t "$claude" -c "$dir")
git=$(tmux split-window -v -d -P -F '#{pane_id}' -t "$nvim" -c "$dir")
k9s=$(tmux split-window -h -d -P -F '#{pane_id}' -t "$git" -c "$dir")
shell=$(tmux split-window -v -d -P -F '#{pane_id}' -t "$k9s" -c "$dir")
tmux set-option -p -t "$k9s" @role k9s
tmux set-option -p -t "$shell" @role shell
tmux set-option -p -t "$nvim" @role nvim
tmux set-option -p -t "$git" @role git
tmux send-keys -t "$nvim" nvim Enter
tmux send-keys -t "$git" lazygit Enter
tmux send-keys -t "$k9s" k9s Enter
tmux resize-pane -t "$claude" -Z
