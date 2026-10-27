#!/usr/bin/env bash
# Print the background hex for a kube cluster name. Single source of truth for
# tmux (kube-switch.sh) and fish (change_kubernetes_cluster_variable).
#   red   live (technosylva + platform)      green platform non-live / local
#   blue  technosylva sandbox                default everything else
case "$1" in
  *live*)                        echo '#8E1600' ;;
  *docker-desktop*|*kind*)       echo '#303b33' ;;
  platform-*|k8s-platform-*)     echo '#303b33' ;;
  *sandbox*)                     echo '#3c307f' ;;
  *)                             echo '#222436' ;;
esac
