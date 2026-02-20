#!/bin/bash
swaymsg workspace number 3
if pgrep -x "chrome" > /dev/null || pgrep -x "google-chrome" > /dev/null; then
    google-chrome "$@"
else
    google-chrome "$@" &
fi
