-- Integration state shared between components
local M = {}

-- For storing global state data
M.last_summary_data = nil
M.overridden_components = {}
M.visualizer_module = nil

-- Debug notification utility
function M.notify_debug(msg)
	if vim.g.alloy_debug then
		vim.notify("Alloy Debug: " .. msg, vim.log.levels.DEBUG)
	end
end

return M

