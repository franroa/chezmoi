#!/usr/bin/env bash
# Update starship accent colors from wallust theme

STARSHIP_CONFIG="$HOME/.config/starship.toml"
WALLUST_COLORS="$HOME/.config/waybar/wallust/colors-waybar.css"
CACHE_FILE="$HOME/.cache/starship_accent"

[ -f "$WALLUST_COLORS" ] || exit 0
[ -f "$STARSHIP_CONFIG" ] || exit 0

new_accent=$(grep -oP '@define-color color12 \K#[0-9A-Fa-f]{6}' "$WALLUST_COLORS" | head -1)
[ -z "$new_accent" ] && exit 0

if [ -f "$CACHE_FILE" ]; then
    old_accent=$(cat "$CACHE_FILE")
else
    old_accent="#769ff0"
fi

if [ "$old_accent" != "$new_accent" ]; then
    sed -i "s/${old_accent}/${new_accent}/gi" "$STARSHIP_CONFIG"
    sed -i "s/#769ff0/${new_accent}/gi" "$STARSHIP_CONFIG"
fi

echo "$new_accent" > "$CACHE_FILE"
