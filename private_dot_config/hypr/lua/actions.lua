-- Small helpers shared by binds and gestures; replace the old `hyprctl keyword ... | awk` / `workspaceopt` hacks.
local M = {}

-- Multiply the cursor zoom factor (never below 1x)
function M.zoom(mult)
    local z = tonumber(hl.get_config("cursor.zoom_factor")) or 1
    hl.config({ cursor = { zoom_factor = math.max(1, z) * mult } })
end

-- Old `workspaceopt allfloat`: float every window of the active workspace, or tile them all if all are floating
function M.toggle_all_float()
    local ws = hl.get_active_workspace()
    if ws == nil then return end
    local windows = hl.get_workspace_windows(ws)
    local any_tiled = false
    for _, w in ipairs(windows) do
        if not w.floating then any_tiled = true end
    end
    for _, w in ipairs(windows) do
        hl.dispatch(hl.dsp.window.float({ action = any_tiled and "set" or "unset", window = w }))
    end
end

-- Park the active floating window on workspace 99 (hidden), and bring parked windows back
function M.hide_floating()
    local w = hl.get_active_window()
    if w ~= nil and w.floating then
        hl.dispatch(hl.dsp.window.move({ workspace = 99, follow = false, window = w }))
    end
end

function M.restore_hidden()
    local ws = hl.get_active_workspace()
    if ws == nil then return end
    for _, w in ipairs(hl.get_windows()) do
        if w.workspace ~= nil and w.workspace.id == 99 then
            hl.dispatch(hl.dsp.window.move({ workspace = ws.id, follow = false, window = w }))
        end
    end
end

return M
