local M = {}

local utils = require("core.utils")
local parser = require("core.parser")
local state = require("features.common.state")
local diagram_utils = require("ui.diagram_utils")

local ns_id_follow = utils.create_namespace("AlloyPipelineFollow")

function M.follow_component_in_diagram()
	local current_state = state.get_state()
	if state.is_syncing() or not current_state or not vim.api.nvim_win_is_valid(current_state.win_id) then
		return
	end
	local components, _, _ = parser.get_parsed_pipeline_data(current_state.source_bufnr)
	if not components then
		return
	end
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local current_component_key = nil
	for key, comp_data in pairs(components) do
		if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
			current_component_key = key
			break
		end
	end
	local diagram_buf = current_state.buf
	vim.api.nvim_buf_clear_namespace(diagram_buf, ns_id_follow, 0, -1)
	if not current_component_key then
		return
	end
	local target_box = nil
	for _, box in ipairs(current_state.box_metadata) do
		if box.key == current_component_key then
			target_box = box
			break
		end
	end
	if not target_box then
		return
	end
	if current_state.type == "vertical_list" then
		vim.api.nvim_buf_add_highlight(
			diagram_buf,
			ns_id_follow,
			"DiagramBoxFollow",
			target_box.line_in_diagram - 1,
			0,
			-1
		)
	else
		for i = 0, 3 do
			vim.api.nvim_buf_add_highlight(
				diagram_buf,
				ns_id_follow,
				"DiagramBoxFollow",
				target_box.line_in_diagram - 1 + i,
				0,
				-1
			)
		end
	end
	state.set_syncing(true)
	if target_box then
		diagram_utils.jump_to_component(current_state, current_component_key)
	end
	state.set_syncing(false)
end

return M