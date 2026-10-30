#!/bin/bash
if command -v hyprctl > /dev/null; then
    hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })' > /dev/null
elif command -v swaymsg > /dev/null; then
    swaymsg workspace number 3 > /dev/null
fi
if pgrep -x "chrome" > /dev/null || pgrep -x "google-chrome" > /dev/null; then
    google-chrome "$@"
else
    google-chrome "$@" &
fi
