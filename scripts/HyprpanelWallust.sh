#!/usr/bin/env bash
# Start hyprpanel with wallust color integration
# Uses hyprpanel-fixed which has sass --no-charset for GTK compatibility
# NOTE: Does NOT regenerate wallust colors - uses cached files from wallpaper change
# This ensures theme changes (Mod+T) don't affect HyprPanel style

WALLUST_COLORS="$HOME/.cache/wallust/hyprpanel-colors.json"
HYPRPANEL_CONFIG="$HOME/.config/hyprpanel/config.json"

# Merge wallust colors if both files exist
if [[ -f "$WALLUST_COLORS" ]] && [[ -f "$HYPRPANEL_CONFIG" ]]; then
  jq -s '.[0] * .[1]' "$HYPRPANEL_CONFIG" "$WALLUST_COLORS" > "${HYPRPANEL_CONFIG}.tmp" && \
    mv "${HYPRPANEL_CONFIG}.tmp" "$HYPRPANEL_CONFIG"
fi

# Regenerate modules.scss with wallust colors + dynamic states
~/.config/hyprpanel/scripts/generate-modules-scss.sh

# Kill hyprpanel if running
pkill -9 -f "\.hyprpanel" 2>/dev/null
sleep 0.3

# Clean CSS directory  
rm -rf /tmp/hyprpanel
mkdir -p /tmp/hyprpanel

# Start hyprpanel-fixed (uses sass --no-charset)
~/.local/bin/hyprpanel-fixed &
