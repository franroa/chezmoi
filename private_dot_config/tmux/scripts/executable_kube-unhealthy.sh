#!/usr/bin/env bash
# Pods that are not Running/Completed, plus pods with not-ready containers or
# more than 5 restarts, across all namespaces of the current kube context.
set -uo pipefail

echo "☸ unhealthy pods in $(kubectl config current-context 2>/dev/null) ..."
echo
kubectl get pods -A -o wide --no-headers 2>&1 | awk '
  {
    split($3, r, "/")
    if ($4 != "Running" && $4 != "Completed" || r[1] != r[2] || $5 + 0 > 5) print
  }' | column -t | less -R
