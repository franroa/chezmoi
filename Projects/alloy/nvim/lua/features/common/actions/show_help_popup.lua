local M = {}

local state = require("features.common.state")
local ui = require("features.common.ui")

function M.show_help_popup()
	local current_state = state.get_state()
	ui.create_help_popup(current_state.type)
end

return M