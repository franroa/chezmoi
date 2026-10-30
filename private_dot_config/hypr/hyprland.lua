-- Hyprland Lua config (Hyprland >= 0.55). Replaces hyprland.conf; see https://wiki.hypr.land/0.56.0/Configuring/Start/
-- Each require() runs in its own scope, so an error in one module does not stop the others.

require("lua.env")
require("monitors")      -- written by nwg-displays
require("workspaces")    -- written by nwg-displays
require("lua.settings")
require("lua.decorations")
require("lua.animations")
require("lua.devices")
require("lua.rules")
require("lua.binds")
require("lua.autostart")
