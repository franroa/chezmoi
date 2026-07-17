#!/usr/bin/env bash
# Prepare HyprPanel theming and (re)start it under its supervised systemd user
# service (hyprpanel.service, Restart=always) so a boot-time or runtime crash
# recovers automatically instead of leaving no panel.
#
# Single entry point for: boot autostart (exec-once in Startup_Apps.conf),
# the reload keybind (Mod+Shift+C), and wallpaper recolor (WallpaperSelect.sh /
# RefreshNoWaybar.sh). Does NOT launch hyprpanel directly and does NOT pkill —
# systemctl owns the lifecycle, so a stray manual `pkill` would just fight the
# supervisor. Logs go to the journal: `journalctl --user -u hyprpanel.service`.
#
# NOTE: Does NOT regenerate wallust colors - uses cached files from wallpaper
# change so theme changes (Mod+T) don't affect HyprPanel style.

WALLUST_COLORS="$HOME/.cache/wallust/hyprpanel-colors.json"
HYPRPANEL_CONFIG="$HOME/.config/hyprpanel/config.json"

# Merge wallust colors if both files exist
if [[ -f "$WALLUST_COLORS" ]] && [[ -f "$HYPRPANEL_CONFIG" ]]; then
  jq -s '.[0] * .[1]' "$HYPRPANEL_CONFIG" "$WALLUST_COLORS" > "${HYPRPANEL_CONFIG}.tmp" && \
    mv "${HYPRPANEL_CONFIG}.tmp" "$HYPRPANEL_CONFIG"
fi

# Regenerate modules.scss with wallust colors + dynamic states
~/.config/hyprpanel/scripts/generate-modules-scss.sh

# Clean CSS output dir
rm -rf /tmp/hyprpanel
mkdir -p /tmp/hyprpanel

# Push the live session env into the systemd user manager. HYPRLAND_INSTANCE_
# SIGNATURE changes every login, so the service can only reach the compositor if
# these are refreshed before (re)start.
systemctl --user import-environment \
  WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE \
  XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS 2>/dev/null

# (Re)start under supervision. `restart` == `start` if not already running.
systemctl --user restart hyprpanel.service
