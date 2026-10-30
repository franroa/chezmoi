#!/bin/bash
# Keybinding menu using rofi (migrated from wofi)
# Shows available keybindings from Hyprland config

# Binds come straight from the running compositor (descriptions are set in lua/binds.lua)
"$HOME/.config/hypr/scripts/keybinds-list.sh" | rofi -dmenu -i -p "Keybindings" -theme-str 'window {width: 50%;}'
