#!/usr/bin/env bash
# Print the background hex for a kube cluster name. Single source of truth for
# tmux (kube-switch.sh) and fish (change_kubernetes_cluster_variable).
#   red    live                    green  test / local
#   grey   sandbox, everything else (tokyonight bg)
case "$1" in
  *live*)                        echo '#8E1600' ;;
  *docker-desktop*|*kind*)       echo '#303b33' ;;
  *test*)                        echo '#303b33' ;;
  *)                             echo '#222436' ;;
esac
