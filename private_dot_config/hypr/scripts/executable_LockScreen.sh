#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Update weather cache in background (non-blocking)
bash "$HOME/.config/hypr/UserScripts/WeatherWrap.sh" >/dev/null 2>&1 &

# # Enable DND so notifications are suppressed while locked
# hyprpanel dnd

loginctl lock-session
