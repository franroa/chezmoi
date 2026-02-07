#!/usr/bin/env bash
# Merge wallust-generated colors into hyprpanel config.json

WALLUST_COLORS="$HOME/.cache/wallust/hyprpanel-colors.json"
HYPRPANEL_CONFIG="$HOME/.config/hyprpanel/config.json"

if [[ ! -f "$WALLUST_COLORS" ]]; then
  echo "Wallust colors not found: $WALLUST_COLORS"
  exit 1
fi

if [[ ! -f "$HYPRPANEL_CONFIG" ]]; then
  echo "Hyprpanel config not found: $HYPRPANEL_CONFIG"
  exit 1
fi

# Merge wallust colors into hyprpanel config using jq
jq -s '.[0] * .[1]' "$HYPRPANEL_CONFIG" "$WALLUST_COLORS" > "${HYPRPANEL_CONFIG}.tmp" && \
  mv "${HYPRPANEL_CONFIG}.tmp" "$HYPRPANEL_CONFIG"

# Apply new colors via hot-reload (faster than restart)
if pgrep -f hyprpanel >/dev/null; then
  astal -i hyprpanel "useTheme $HYPRPANEL_CONFIG" 2>/dev/null || {
    # Fallback to restart if hot-reload fails
    hyprpanel -q 2>/dev/null
    sleep 0.5
    hyprpanel &
  }
else
  hyprpanel &
fi
