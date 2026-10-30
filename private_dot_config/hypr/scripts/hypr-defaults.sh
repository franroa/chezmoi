#!/usr/bin/env bash
# Reads the user defaults from ~/.config/hypr/lua/vars.lua (single source of truth, shared with hyprland.lua).
# Usage: source "$HOME/.config/hypr/scripts/hypr-defaults.sh"   -> sets $term $files $edit $Search_Engine

vars_lua="${HYPR_VARS_LUA:-$HOME/.config/hypr/lua/vars.lua}"

# Value of the first quoted string on the `<name> = "..."` line; a leading `home ..` expands to $HOME
_hl_var() {
    local line val
    line=$(grep -m1 -E "^[[:space:]]*$1[[:space:]]*=" "$vars_lua") || return 1
    val=${line#*\"}
    val=${val%\"*}
    [[ $line == *'home ..'* ]] && val="$HOME$val"
    printf '%s' "$val"
}

if [[ ! -f "$vars_lua" ]]; then
    echo "Error: $vars_lua not found!" >&2
    return 1 2>/dev/null || exit 1
fi

term=$(_hl_var term)
files=$(_hl_var files)
edit=$(_hl_var editor)
Search_Engine=$(_hl_var searchEngine)
