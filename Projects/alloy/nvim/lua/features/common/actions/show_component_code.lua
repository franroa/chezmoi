local M = {}

local state = require("features.common.state")
local ui = require("features.common.ui")
local diagram_utils = require("ui.diagram_utils")

function M.show_component_code()
	local current_state = state.get_state()
	ui.close_component_popup()
	local _, box =
		diagram_utils.get_box_at_cursor(current_state.win_id, current_state.box_metadata, current_state.type)
	if box then
		local popup_opts = {
			parent_win_id = current_state.win_id,
		}
		if current_state.type == "horizontal" then
			popup_opts.layout = "horizontal_manual"
		end
		state.update_state("popup_win_id", ui.open_component_popup(box, popup_opts))
	end
end

return M