#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Modified version of Refresh.sh but waybar wont refresh
# Used by automatic wallpaper change

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Kill already running processes
_ps=(rofi)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# quit ags & relaunch ags (if installed)
if command -v ags >/dev/null 2>&1; then
    ags -q 2>/dev/null
    ags &
fi

# quit waybar & relaunch waybar (if installed)
if command -v qs >/dev/null 2>&1; then
    pkill qs 2>/dev/null
    qs &
fi

# reload swaync (if running)
swaync-client --reload-config 2>/dev/null || true

# Update hyprpanel colors and restart
sleep 0.5
${SCRIPTSDIR}/HyprpanelWallust.sh &

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
    ${UserScripts}/RainbowBorders.sh &
fi

exit 0
