-- Monitor quirks that can't live in monitors.lua (nwg-displays rewrites that file).
--
-- Acer VG270K (NVIDIA MST via Lenovo 40AY dock) on Hyprland 0.57: nvidia-drm rejects the first
-- modesets with EINVAL, aquamarine retries forever (~700 failed commits/s, Hyprland at 100% CPU)
-- and the kernel CRTC can be left at 640x480 while `hyprctl monitors` still says 3840x2160.
-- Recovery: DPMS off/on stops the loop, then bounce through another mode and re-apply
-- monitors.lua to force a real modeset. Only runs when the loop is detected.

local MATCH = "VG270K"
local CHECK_DELAY_MS = 4000
local STUCK_LOG_GROWTH = 20000 -- bytes/s; the commit-failure loop writes ~70 KB/s

local timers = {} -- keep references so pending timers aren't garbage-collected
local busy = false

local function after(ms, fn)
    local t
    t = hl.timer(function()
        timers[t] = nil
        fn()
    end, { timeout = ms, type = "oneshot" })
    timers[t] = true
end

local function log(msg)
    os.execute("logger -t monitor-quirks " .. string.format("%q", msg))
end

local function find_acer()
    for _, m in ipairs(hl.get_monitors({ all = true })) do
        if m.description and m.description:find(MATCH, 1, true) then
            return m
        end
    end
end

local function log_size()
    local f = io.open(os.getenv("XDG_RUNTIME_DIR") .. "/hypr/" .. os.getenv("HYPRLAND_INSTANCE_SIGNATURE") .. "/hyprland.log", "r")
    if not f then
        return nil
    end
    local size = f:seek("end")
    f:close()
    return size
end

local function reapply_monitors()
    package.loaded["monitors"] = nil
    require("monitors")
end

local function check_acer()
    if busy or not find_acer() then
        return
    end
    busy = true
    after(CHECK_DELAY_MS, function()
        local acer = find_acer()
        local before = log_size()
        if not acer or not before then
            busy = false
            return
        end
        after(1000, function()
            local growth = (log_size() or before) - before
            if growth < STUCK_LOG_GROWTH then
                busy = false
                return
            end
            local name, desc = acer.name, "desc:" .. acer.description
            log(name .. " stuck in modeset loop (" .. growth .. " B/s log growth), recovering")
            hl.dispatch(hl.dsp.dpms({ action = "off", monitor = name }))
            after(2000, function()
                hl.dispatch(hl.dsp.dpms({ action = "on", monitor = name }))
                after(2000, function()
                    hl.monitor({ output = desc, mode = "2560x1440@60", position = "1920x0", scale = 1 })
                    after(3000, function()
                        reapply_monitors()
                        -- swww keeps the frame drawn during the broken modes; repaint it.
                        after(1500, function()
                            hl.exec_cmd("swww img --outputs " .. name
                                .. " --transition-type none $HOME/.config/hypr/wallpaper_effects/.wallpaper_current")
                            log(name .. " recovery done")
                            busy = false
                        end)
                    end)
                end)
            end)
        end)
    end)
end

hl.on("hyprland.start", check_acer)
hl.on("monitor.added", check_acer)
