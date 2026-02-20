#!/bin/bash
current=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused).num')
if [ "$current" -eq 1 ]; then
	prev=10
else
	prev=$((current - 1))
fi
swaymsg workspace number $prev
