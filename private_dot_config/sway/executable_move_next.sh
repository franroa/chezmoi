#!/bin/bash
current=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused).num')
if [ "$current" -eq 10 ]; then
	next=1
else
	next=$((current + 1))
fi
swaymsg move container to workspace number $next
