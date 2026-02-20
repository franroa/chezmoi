#!/bin/bash
# Right-click context menu for sway desktop

options="  Terminal
  File Manager
  Browser
  Screenshot
  Screen Record
  Lock Screen
  Reload Sway
  Night Light Toggle
  Quick Settings"

chosen=$(echo -e "$options" | rofi -dmenu -p "Menu" -i -theme-str 'window {width: 200px;}')

case "$chosen" in
    *"Terminal"*)
        wezterm
        ;;
    *"File Manager"*)
        nautilus || nemo || thunar || pcmanfm
        ;;
    *"Browser"*)
        firefox
        ;;
    *"Screenshot"*)
        grimshot save area - | swappy -f -
        ;;
    *"Screen Record"*)
        if pgrep wf-recorder > /dev/null; then
            killall -s SIGINT wf-recorder
            notify-send "Recording" "Stopped"
        else
            wf-recorder -g "$(slurp)" -f ~/Videos/recording-$(date +%Y%m%d_%H%M%S).mp4 &
            notify-send "Recording" "Started"
        fi
        ;;
    *"Lock"*)
        swaylock -f -c 000000
        ;;
    *"Reload"*)
        swaymsg reload
        ;;
    *"Night Light"*)
        if pgrep gammastep > /dev/null; then
            pkill gammastep
            notify-send "Night Light" "Disabled"
        else
            gammastep &
            notify-send "Night Light" "Enabled"
        fi
        ;;
    *"Quick Settings"*)
        ~/.config/waybar/scripts/quicksettings.sh
        ;;
esac
