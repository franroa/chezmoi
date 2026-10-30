-- Per-device config and gestures (was configs/Laptops.conf device blocks + SystemSettings.conf gestures)
local v = require("lua.vars")
local actions = require("lua.actions")

hl.device({
    name = v.touchpadDevice,
    enabled = true,
})

hl.device({
    name = "wacom-intuos-bt-m-pen",
    output = "DP-1",
    left_handed = false,
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up",   action = function() actions.zoom(1.5) end })
hl.gesture({ fingers = 4, direction = "down", action = function() actions.zoom(1 / 1.5) end })
hl.gesture({ fingers = 3, direction = "up",   action = function() hl.exec_cmd(v.scriptsDir .. "/OverviewToggle.sh") end })
