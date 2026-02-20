#!/bin/bash
# Wofi Theme Switcher with Live Preview
# Relaunches wofi with each theme as you navigate

THEMES_DIR="$HOME/.config/wofi/themes"
CURRENT_THEME_FILE="$HOME/.config/wofi/current-theme"
WLR_CONFIG="$HOME/.config/wlr-which-key/config.yaml"
PREVIEW_INDEX_FILE="/tmp/wofi-theme-index"
ORIGINAL_THEME_FILE="/tmp/wofi-original-theme"

declare -A THEME_COLORS=(
    ["arc-dark"]="#383c4ad0 #d3dae3 #5294e2"
    ["catppuccin-mocha"]="#1e1e2ed0 #cdd6f4 #cba6f7"
    ["dracula"]="#282a36d0 #f8f8f2 #bd93f9"
    ["everforest"]="#2d353bd0 #d3c6aa #a7c080"
    ["gruvbox-dark"]="#282828d0 #ebdbb2 #d79921"
    ["launchpad"]="#242424d0 #f5f5f5 #0860f2"
    ["material-dark"]="#212121d0 #fafafa #00bcd4"
    ["nord"]="#2e3440d0 #eceff4 #88c0d0"
    ["onedark"]="#282c34d0 #abb2bf #61afef"
    ["rose-pine"]="#191724d0 #e0def4 #ebbcba"
    ["solarized-dark"]="#002b36d0 #839496 #268bd2"
    ["tokyonight"]="#1a1b26d0 #c0caf5 #7aa2f7"
)

get_themes() {
    ls "$THEMES_DIR"/*.css 2>/dev/null | xargs -I {} basename {} .css | sort
}

get_current_theme() {
    [[ -f "$CURRENT_THEME_FILE" ]] && cat "$CURRENT_THEME_FILE" || echo "tokyonight"
}

update_wlr_which_key() {
    local theme_name="$1"
    local colors="${THEME_COLORS[$theme_name]}"
    [[ -z "$colors" ]] && return
    read -r bg fg border <<< "$colors"
    sed -i "s/^background: .*/background: \"$bg\"/" "$WLR_CONFIG"
    sed -i "s/^color: .*/color: \"$fg\"/" "$WLR_CONFIG"
    sed -i "s/^border: .*/border: \"$border\"/" "$WLR_CONFIG"
}

apply_theme() {
    local theme_name="$1"
    [[ ! -f "$THEMES_DIR/$theme_name.css" ]] && return
    echo "$theme_name" > "$CURRENT_THEME_FILE"
    ln -sf "$THEMES_DIR/$theme_name.css" "$HOME/.config/wofi/active-theme.css"
    update_wlr_which_key "$theme_name"
}

show_picker() {
    local preview_theme="$1"
    local current=$(get_current_theme)
    local themes=$(get_themes)
    local menu=""
    
    while IFS= read -r theme; do
        if [[ "$theme" == "$current" ]]; then
            menu+="● $theme (current)\n"
        else
            menu+="  $theme\n"
        fi
    done <<< "$themes"
    
    echo -e "$menu" | head -c -1 | wofi --dmenu \
        --prompt "󰔎 Theme" \
        --style "$THEMES_DIR/$preview_theme.css" \
        --cache-file=/dev/null \
        --insensitive \
        --allow-markup
}

# Save original theme
original=$(get_current_theme)
echo "$original" > "$ORIGINAL_THEME_FILE"

# Main loop - restart wofi with new theme on each selection
preview_theme="$original"
while true; do
    selected=$(show_picker "$preview_theme")
    
    # User pressed Escape or closed wofi
    if [[ -z "$selected" ]]; then
        # Restore original theme
        apply_theme "$original"
        notify-send -t 1500 "Theme" "Cancelled - restored $original"
        break
    fi
    
    # Extract theme name
    theme_name=$(echo "$selected" | sed 's/^[● ] //' | sed 's/ (current)$//')
    
    # Check if same theme selected (confirm)
    if [[ "$theme_name" == "$preview_theme" ]]; then
        apply_theme "$theme_name"
        notify-send -t 2000 "Theme Applied" "$theme_name"
        break
    fi
    
    # Preview the new theme
    preview_theme="$theme_name"
    apply_theme "$preview_theme"
done

rm -f "$ORIGINAL_THEME_FILE" "$PREVIEW_INDEX_FILE"
