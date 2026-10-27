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
# status line follows the cluster color too (it otherwise uses the terminal default bg)
tmux set-option -t "$target" status-style "bg=$color"
tmux set-hook -t "$target" after-new-window "run-shell -b '$HOME/.config/tmux/scripts/kube-switch.sh -t $target'"

# claude: its process env is frozen at launch (and its pane predates this script),
# so inject through the project's settings.local.json, which claude re-reads live
dir=$("$HOME/.config/tmux/scripts/workspace-dir.sh" -t "$target")
ns=$(KUBECONFIG="$link" kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
if [ -d "$dir" ] && [ "$dir" != "$HOME" ]; then
  f="$dir/.claude/settings.local.json"
  mkdir -p "$dir/.claude"
  [ -s "$f" ] || echo '{}' > "$f"
  tmp=$(mktemp "$f.XXXXXX") && jq --arg c "$cluster" --arg n "$ns" --arg k "$link" \
    '.env = ((.env // {}) + {K8S_CLUSTER: $c, K8S_NAMESPACE: $n, KUBECONFIG: $k})' "$f" > "$tmp" \
    && mv "$tmp" "$f" || rm -f "$tmp"
fi

# k9s: restart every k9s pane on the new context (tagged by @role or running k9s)
for k9s in $(tmux list-panes -t "$target" -s -F $'#{pane_id}\t#{@role}\t#{pane_current_command}' | awk -F'\t' '$2=="k9s" || $3=="k9s" {print $1}'); do
  case "$(tmux display -p -t "$k9s" '#{pane_current_command}')" in
    bash|zsh|fish|sh|dash) ;;                 # app already exited: leave the shell alone
    *) tmux send-keys -t "$k9s" C-c; sleep 0.3 ;;
  esac
  tmux send-keys -t "$k9s" k9s Enter
done

# wake fish shells (see __tmux_kube_sync in config.fish)
command -v fish >/dev/null && fish -c "set -U __tmux_kube_rev $RANDOM$RANDOM" 2>/dev/null
tmux display-message "⎈ $cluster"
