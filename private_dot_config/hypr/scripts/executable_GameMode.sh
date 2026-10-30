#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


# Preserve eDP-1's current position/scale from the live layout (monitors.lua is the
# source of truth for placement) — this script must only switch the refresh rate.
EDP_POS=$(hyprctl -j monitors | jq -r '.[] | select(.name=="eDP-1") | "\(.x)x\(.y)"')
EDP_SCALE=$(hyprctl -j monitors | jq -r '.[] | select(.name=="eDP-1") | .scale')
EDP_POS=${EDP_POS:-4152x448}
EDP_SCALE=${EDP_SCALE:-1.25}

HYPRGAMEMODE=$(hyprctl -j getoption animations.enabled | jq -r '.bool')
if [ "$HYPRGAMEMODE" = true ] ; then
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
        general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
    })'

    # Dropped again by the `hyprctl reload` in the disable branch
    hyprctl eval 'hl.window_rule({ name = "gamemode-opaque", match = { class = ".*" }, opacity = "1 override 1 override 1 override" })'
    hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2560x1600@240\", position = \"${EDP_POS}\", scale = ${EDP_SCALE} })"
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled (240Hz)"
    # Keep the wallpaper in game mode: ensure the daemon is alive and
    # re-render after the 240Hz mode switch so the background persists.
    swww query &>/dev/null || swww-daemon --format xrgb &
    sleep 0.2
    swww img "$HOME/.config/rofi/.current_wallpaper"
    exit
else
	swww-daemon --format xrgb && swww img "$HOME/.config/rofi/.current_wallpaper" &
	sleep 0.1
	# Do NOT run WallustSwww.sh here: it regenerates colors from the wallpaper,
	# which clobbers a theme chosen via Mod+T (ThemeChanger.sh). Game mode must
	# only toggle animations/refresh rate, never the theme.
	hyprctl reload
	hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2560x1600@60\", position = \"${EDP_POS}\", scale = ${EDP_SCALE} })"
	${SCRIPTSDIR}/RefreshNoWaybar.sh
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled (60Hz)"
    exit
fi
hyprctl reload
