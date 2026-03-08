#!/usr/bin/env bash
# Screenshot chooser for hyprpanel dashboard

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
sDIR="$HOME/.config/hypr/scripts"

if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
fi

choice=$(printf "Full Screen\nRegion / Area" | rofi -dmenu -p "Screenshot" -mesg "Choose screenshot type" -theme-str 'listview {lines: 2;}')

case "$choice" in
    "Full Screen")
        "$sDIR/ScreenShot.sh" --now
        ;;
    "Region / Area")
        "$sDIR/ScreenShot.sh" --area
        ;;
esac
