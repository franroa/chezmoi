#!/usr/bin/env bash
# Point a tmux session at a kube cluster and propagate it to every pane.
#   kube-switch.sh [<cluster>] [-t <session-id>]
# Without <cluster> the session's @kube_cluster is re-applied (init / new window).
# Each session owns ~/.kube/tmux/<sid>.yaml, a symlink to ~/.kube/<cluster>.yaml;
# KUBECONFIG points at it, so kubectl/k9s/claude follow a re-link with no restart.
cluster=""; target=""
while [ $# -gt 0 ]; do
  case "$1" in
    -t) target="$2"; shift 2 ;;
    *)  cluster="$1"; shift ;;
  esac
done
[ -n "$target" ] || target=$(tmux display -p '#{session_id}')
sid="${target#\$}"
dir="$HOME/.kube/tmux"; link="$dir/$sid.yaml"
mkdir -p "$dir"

[ -n "$cluster" ] || cluster=$(tmux show -t "$target" -qv @kube_cluster)
[ -n "$cluster" ] || cluster=$(tmux show -gqv @kube_last_cluster)
[ -n "$cluster" ] || cluster=default
if [ "$cluster" = default ]; then src="$HOME/.kube/config"; else src="$HOME/.kube/$cluster.yaml"; fi
[ -f "$src" ] || { tmux display-message "kube: no kubeconfig for $cluster"; exit 1; }

ln -sfn "$src" "$link"
tmux set-environment -t "$target" KUBECONFIG "$link"
tmux set-environment -t "$target" K8S_CLUSTER "$cluster"
tmux set-option -t "$target" @kube_cluster "$cluster"
[ "$cluster" = default ] || tmux set-option -g @kube_last_cluster "$cluster"

color=$("$HOME/.config/tmux/scripts/kube-color.sh" "$cluster")
for w in $(tmux list-windows -t "$target" -F '#{window_id}'); do
  tmux set-option -w -t "$w" window-style "bg=$color"
  tmux set-option -w -t "$w" window-active-style "bg=$color"
done
tmux set-hook -t "$target" after-new-window "run-shell -b '$HOME/.config/tmux/scripts/kube-switch.sh -t $target'"

# k9s: restart on the new context
k9s=$(tmux list-panes -t "$target" -s -F $'#{pane_id}\t#{@role}\t#{pane_current_command}' | awk -F'\t' '$2=="k9s" && $3=="k9s" {print $1; exit}')
if [ -n "$k9s" ]; then
  tmux send-keys -t "$k9s" C-c
  sleep 0.3
  tmux send-keys -t "$k9s" k9s Enter
fi

# wake fish shells (see __tmux_kube_sync in config.fish)
command -v fish >/dev/null && fish -c "set -U __tmux_kube_rev $RANDOM$RANDOM" 2>/dev/null
tmux display-message "⎈ $cluster"
