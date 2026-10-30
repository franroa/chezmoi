#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# This file used on waybar modules sourcing defaults set in $HOME/.config/hypr/lua/vars.lua

# $term, $files, $edit come from lua/vars.lua
source "$HOME/.config/hypr/scripts/hypr-defaults.sh" || exit 1

# Check if $term is set correctly
if [[ -z "$term" ]]; then
    echo "Error: \$term is not set in the configuration file!"
    exit 1
fi

# Execute accordingly based on the passed argument
launch_files() {
    if [[ -z "$files" ]]; then
        notify-send -u low -i "$HOME/.config/swaync/images/error.png" "Waybar: files" "Set \$files in lua/vars.lua or install a default file manager."
        return 1
    fi
    eval "$files &"
}

if [[ "$1" == "--btop" ]]; then
    $term --title btop sh -c 'btop'
elif [[ "$1" == "--nvtop" ]]; then
    $term --title nvtop sh -c 'nvtop'
elif [[ "$1" == "--nmtui" ]]; then
    $term nmtui
elif [[ "$1" == "--term" ]]; then
    $term &
elif [[ "$1" == "--files" ]]; then
    launch_files
else
    echo "Usage: $0 [--btop | --nvtop | --nmtui | --term]"
    echo "--btop       : Open btop in a new term"
    echo "--nvtop      : Open nvtop in a new term"
    echo "--nmtui      : Open nmtui in a new term"
    echo "--term   : Launch a term window"
    echo "--files  : Launch a file manager"
fi