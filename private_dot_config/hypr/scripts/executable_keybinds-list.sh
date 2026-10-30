#!/usr/bin/env bash
# Prints "MODS + KEY<TAB>description" for every described bind of the running Hyprland (descriptions are set in lua/binds.lua).

hyprctl -j binds | jq -r '
def mods($m): [
  (if (($m / 64 | floor) % 2) == 1 then "SUPER" else empty end),
  (if (($m / 4 | floor) % 2) == 1 then "CTRL" else empty end),
  (if (($m / 8 | floor) % 2) == 1 then "ALT" else empty end),
  (if ($m % 2) == 1 then "SHIFT" else empty end)
];
.[] | select(.has_description) | . as $b
| ((mods($b.modmask) + [$b.key]) | join(" + ")) + "\t" + $b.description' | sort | column -t -s "$(printf '\t')"
