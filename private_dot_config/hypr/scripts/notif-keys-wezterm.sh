#!/bin/bash
# Transparent key capture using wezterm

# Open notification panel first
astal -i hyprpanel -t notificationsmenu 2>/dev/null
sleep 0.1

# Create a minimal wezterm window for key capture
# This will be transparent and capture keys

# Generate a simple lua script for wezterm
WEZ_SCRIPT="/tmp/notif-keys-$USER.lua"

cat > "$WEZ_SCRIPT" << 'EOF'
local wezterm = require 'wezterm'
local act = wezterm.action

return {
  window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
  window_background_opacity = 0,
  text_background_opacity = 0,
  enable_tab_bar = false,
  hide_tab_bar_if_only_one_tab = true,
  window_decorations = "NONE",
  
  keys = {
    {
      key = "e",
      mods = "NONE",
      action = act.Callback(function(win, pane)
        win:event_close()
        os.execute("~/.config/hypr/scripts/notif-trigger-direct.sh opencode e &")
      end),
    },
  },
  
  initial_rows = 1,
  initial_cols = 1,
}
EOF

# Spawn wezterm with this config
wezterm start \
  --config-file "$WEZ_SCRIPT" \
  --position 0,0 \
  --geometry 1x1 \
  --no-workdir \
  --always-new-process &
