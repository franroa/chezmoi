#!/usr/bin/env bash
# Called by the k9s "switch-context" plugin: pick a context with fzf and reopen
# k9s on it, landing on the same resource view you were looking at.
# Usage: k9s-switch-ctx.sh <resource-group> <resource-version> <resource-name>
group=$1 version=$2 name=$3

ctx=$(kubectl config get-contexts -o name | fzf --prompt='context> ' --height=40% --reverse) || exit 0

# Core resources have an empty group, so there is no leading "group/"
gvr=${group:+$group/}$version/$name

exec k9s --context "$ctx" --command "$gvr"
