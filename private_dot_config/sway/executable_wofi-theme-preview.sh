#!/bin/bash
# Wofi Theme Previewer - Live preview as you navigate

THEMES_DIR="$HOME/.config/wofi/themes"
CURRENT_THEME_FILE="$HOME/.config/wofi/current-theme"
WLR_CONFIG="$HOME/.config/wlr-which-key/config.yaml"
PREVIEW_PID_FILE="/tmp/wofi-preview-pid"

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

get_current_theme() {
    [[ -f "$CURRENT_THEME_FILE" ]] && cat "$CURRENT_THEME_FILE" || echo "tokyonight"
}

show_preview() {
    local theme="$1"
    pkill -f "wofi.*preview-mode" 2>/dev/null
    sleep 0.05
    echo -e "App 1\nApp 2\nApp 3\nApp 4\nApp 5" | \
        wofi --dmenu --style "$THEMES_DIR/$theme.css" \
        --prompt "Preview: $theme" \
        --width 400 --height 300 \
        --cache-file=/dev/null \
        --define=preview-mode=true \
        --location=top-right &
    echo $! > "$PREVIEW_PID_FILE"
}

cleanup() {
    pkill -f "wofi.*preview-mode" 2>/dev/null
    rm -f "$PREVIEW_PID_FILE"
}

apply_theme() {
    local theme_name="$1"
    if [[ -f "$THEMES_DIR/$theme_name.css" ]]; then
        echo "$theme_name" > "$CURRENT_THEME_FILE"
        ln -sf "$THEMES_DIR/$theme_name.css" "$HOME/.config/wofi/active-theme.css"
        
        local colors="${THEME_COLORS[$theme_name]}"
        if [[ -n "$colors" ]]; then
            read -r bg fg border <<< "$colors"
            sed -i "s/^background: .*/background: \"$bg\"/" "$WLR_CONFIG"
            sed -i "s/^color: .*/color: \"$fg\"/" "$WLR_CONFIG"
            sed -i "s/^border: .*/border: \"$border\"/" "$WLR_CONFIG"
        fi
        notify-send -t 2000 "Theme Applied" "$theme_name"
    fi
}

trap cleanup EXIT

current=$(get_current_theme)
themes=$(ls "$THEMES_DIR"/*.css | xargs -I {} basename {} .css | sort)

selected=$(echo "$themes" | fzf \
    --header="Theme Selector (↑↓ to preview, Enter to apply, Esc to cancel)" \
    --preview="$0 --preview {}" \
    --preview-window=hidden \
    --bind="focus:execute-silent($0 --preview {})" \
    --highlight-line \
    --pointer="●" \
    --prompt="Theme: " \
    --color="bg:#1a1b26,fg:#c0caf5,hl:#7aa2f7,bg+:#283457,fg+:#c0caf5,hl+:#7aa2f7,info:#7aa2f7,prompt:#7aa2f7,pointer:#f7768e,marker:#9ece6a,spinner:#7aa2f7,header:#565f89")

cleanup

if [[ -n "$selected" ]]; then
    apply_theme "$selected"
else
    apply_theme "$current"
fi
