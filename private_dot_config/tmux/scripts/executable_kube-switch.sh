#!/usr/bin/env bash
# Point a tmux session at a kube cluster and propagate it to every pane.
#   kube-switch.sh [<cluster>] [-t <session-id>]
# Without <cluster> the session's @kube_cluster is re-applied (init / new window).
# A session with no cluster stays cluster-less: no last-used or default fallback.
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

# only an explicit pick (C-b K) is a switch; re-applies (new window, init) are not
explicit=""; [ -n "$cluster" ] && explicit=1
[ -n "$cluster" ] || cluster=$(tmux show -t "$target" -qv @kube_cluster)
if [ -z "$cluster" ]; then
  # no cluster: drop a color left by an earlier switch so the windows show the terminal's background
  for w in $(tmux list-windows -t "$target" -F '#{window_id}'); do
    tmux set-option -wu -t "$w" window-style
    tmux set-option -wu -t "$w" window-active-style
  done
  for p in $(tmux list-panes -t "$target" -s -F '#{pane_id}'); do
    tmux set-option -pu -t "$p" window-style
    tmux set-option -pu -t "$p" window-active-style
    tmux set-option -pu -t "$p" @kube_color
  done
  exit 0
fi
src="$HOME/.kube/$cluster.yaml"
[ -f "$src" ] || { tmux display-message "kube: no kubeconfig for $cluster"; exit 1; }

# <domain>-<tier>-<region>, optional k8s- prefix; domain doubles as sector
tsyl_domain=""; tsyl_tier=""; tsyl_region=""
if [[ "$cluster" =~ ^(k8s-)?([a-z]+)-(live|sandbox|test)-([a-z0-9]+)$ ]]; then
  tsyl_domain=${BASH_REMATCH[2]}; tsyl_tier=${BASH_REMATCH[3]}; tsyl_region=${BASH_REMATCH[4]}
fi

ln -sfn "$src" "$link"
tmux set-environment -t "$target" KUBECONFIG "$link"
tmux set-environment -t "$target" K8S_CLUSTER "$cluster"
tmux set-environment -t "$target" TSYL_DOMAIN "$tsyl_domain"
tmux set-environment -t "$target" TSYL_SECTOR "$tsyl_domain"
tmux set-environment -t "$target" TSYL_TIER "$tsyl_tier"
tmux set-environment -t "$target" TSYL_REGION "$tsyl_region"
tmux set-option -t "$target" @kube_cluster "$cluster"
# fish shells of this session re-apply when the rev changes (see __tmux_kube_sync)
[ -z "$explicit" ] || tmux set-environment -t "$target" KUBE_REV "$RANDOM$RANDOM"

color=$("$HOME/.config/tmux/scripts/kube-color.sh" "$cluster")
for w in $(tmux list-windows -t "$target" -F '#{window_id}'); do
  tmux set-option -w -t "$w" window-style "bg=$color"
  tmux set-option -w -t "$w" window-active-style "bg=$color"
done
# status line follows the cluster color too: the global status-style (workspace.conf)
# reads @kube_color. Not a per-session status-style, because `aoe session start`
# unsets that right after the after-new-session hook has run.
tmux set-option -t "$target" @kube_color "$color"
tmux set-option -u -t "$target" status-style
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

# nvim: its env is frozen at launch. Each nvim listens on $XDG_RUNTIME_DIR/nvim.<pid>.0;
# push the cluster vars into the instances that live in this session's panes.
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
panes=" $(tmux list-panes -t "$target" -s -F '#{pane_id}' | tr '\n' ' ') "
lua_env="'K8S_CLUSTER': '$cluster', 'K8S_NAMESPACE': '$ns', 'KUBECONFIG': '$link', 'TSYL_DOMAIN': '$tsyl_domain', 'TSYL_SECTOR': '$tsyl_domain', 'TSYL_TIER': '$tsyl_tier', 'TSYL_REGION': '$tsyl_region'"
nvim_expr="luaeval(\"(function(t) for k, v in pairs(t) do if v == '' then vim.env[k] = nil else vim.env[k] = v end end end)(_A)\", {$lua_env})"
for sock in "$runtime"/nvim.*.0; do
  [ -S "$sock" ] || continue
  pid=${sock##*/nvim.}; pid=${pid%.0}
  pane=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | sed -n 's/^TMUX_PANE=//p')
  [ -n "$pane" ] || continue
  case "$panes" in *" $pane "*) timeout 2 nvim --server "$sock" --remote-expr "$nvim_expr" >/dev/null 2>&1 ;; esac
done

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
