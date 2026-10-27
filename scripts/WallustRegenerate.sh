#!/bin/bash
# Regenerate wallust colors from current wallpaper
# Useful when you want to refresh colors without changing wallpaper

current_wall="$HOME/.config/rofi/.current_wallpaper"

if [ ! -f "$current_wall" ]; then
    notify-send "Wallust" "No current wallpaper found" -u warning
    exit 1
fi

notify-send "Wallust" "Regenerating colors..." -t 2000

wallust run -s "$current_wall"

# Reload apps that use the colors
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -SIGUSR1 kitty 2>/dev/null || true

notify-send "Wallust" "Colors regenerated!" -t 2000
