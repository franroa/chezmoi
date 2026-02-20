#!/bin/bash
# Cycle through all windows by focus history (most recently used order)
# Usage: cycle_all_windows.sh [next|prev]

direction="${1:-next}"

# Get all windows sorted by focus order (focus field indicates recency)
windows=$(swaymsg -t get_tree | jq -r '
  [recurse(.nodes[]?, .floating_nodes[]?) | select(.type == "con" and .pid != null) | {id: .id, focused: .focused, focus: ((.focus[0]) // 0)}] | sort_by(-.focus)
')

count=$(echo "$windows" | jq 'length')

if [ "$count" -le 1 ]; then
    exit 0
fi

# Find focused window index (should be index 0 in sorted list)
focused_idx=$(echo "$windows" | jq 'to_entries | .[] | select(.value.focused == true) | .key')

if [ -z "$focused_idx" ]; then
    focused_idx=0
fi

# Calculate next/prev index
if [ "$direction" = "next" ]; then
    new_idx=$(( (focused_idx + 1) % count ))
else
    new_idx=$(( (focused_idx - 1 + count) % count ))
fi

# Focus the window
target_id=$(echo "$windows" | jq -r ".[$new_idx].id")
swaymsg "[con_id=$target_id]" focus
