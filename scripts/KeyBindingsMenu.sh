#!/bin/bash
# Keybinding menu using rofi (migrated from wofi)
# Shows available keybindings from Hyprland config

keybinds_file="$HOME/.config/hypr/configs/Keybinds.conf"
user_keybinds="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"

# Extract keybinds with descriptions (bindd format: bindd = MOD, KEY, description, ...)
{
    grep -E "^bindd\s*=" "$keybinds_file" 2>/dev/null
    grep -E "^bindd\s*=" "$user_keybinds" 2>/dev/null
} | sed 's/bindd\s*=\s*//' | \
    awk -F',' '{
        mod=$1; key=$2; desc=$3;
        gsub(/^[ \t]+|[ \t]+$/, "", mod);
        gsub(/^[ \t]+|[ \t]+$/, "", key);
        gsub(/^[ \t]+|[ \t]+$/, "", desc);
        printf "%-20s  %s\n", mod " + " key, desc
    }' | sort | rofi -dmenu -i -p "Keybindings" -theme-str 'window {width: 50%;}'
