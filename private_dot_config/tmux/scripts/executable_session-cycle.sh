#!/usr/bin/env bash

# Cycle to the prev/next session following the SAME order as the status-bar
# letters (creation time, with -T2 mirrors and numeric sessions filtered out).
# Wraps around at the ends.

dir="$1"   # prev | next

current=$(tmux display-message -p '#{session_name}')
[[ "$current" == *-T2 ]] && current="${current%-T2}"

mapfile -t ordered < <(
  tmux list-sessions -F '#{session_created}	#{session_name}' 2>/dev/null \
    | sort -s -n -k1,1 | cut -f2-
)

filtered=()
for s in "${ordered[@]}"; do
  [[ "$s" == *-T2 ]] && continue
  [[ "$s" =~ ^[0-9]+$ ]] && continue
  filtered+=("$s")
done

n=${#filtered[@]}
[ "$n" -le 1 ] && exit 0

cur=0
for i in "${!filtered[@]}"; do
  [ "${filtered[$i]}" = "$current" ] && { cur=$i; break; }
done

if [ "$dir" = prev ]; then
  target=$(( (cur - 1 + n) % n ))
else
  target=$(( (cur + 1) % n ))
fi

tmux switch-client -t "${filtered[$target]}"
tmux refresh-client -S
