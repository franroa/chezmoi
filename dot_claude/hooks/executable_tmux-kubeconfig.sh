#!/usr/bin/env bash
# Keep claude on the tmux session's kube cluster (see tmux scripts/kube-switch.sh).
#   session-start: export KUBECONFIG=~/.kube/tmux/<sid>.yaml into CLAUDE_ENV_FILE
#   prompt:        tell the model which cluster is active (it can change mid-chat)
[ -n "$TMUX_PANE" ] || exit 0
sid=$(tmux display -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null) || exit 0
link="$HOME/.kube/tmux/${sid#\$}.yaml"
[ -e "$link" ] || exit 0
case "$1" in
  session-start) [ -z "$CLAUDE_ENV_FILE" ] || echo "export KUBECONFIG=\"$link\"" >> "$CLAUDE_ENV_FILE" ;;
  prompt) echo "Active Kubernetes cluster (tmux session): $(tmux show -t "$sid" -qv @kube_cluster)" ;;
esac
exit 0
