#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master or Dwindle) on the fly
# The SUPER+J/K/O binds follow general.layout themselves (see lua/binds.lua), so only the layout is switched here.

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general.layout | jq -r '.str')

case $LAYOUT in
"master")
  hyprctl eval 'hl.config({ general = { layout = "dwindle" } })'
  notify-send -e -u low -i "$notif" " Dwindle Layout"
  ;;
"dwindle")
  hyprctl eval 'hl.config({ general = { layout = "master" } })'
  notify-send -e -u low -i "$notif" " Master Layout"
  ;;
*) ;;
esac
