local M = {}

local utils = require("core.utils")
local parser = require("core.parser")
local state = require("features.common.state")
local ui = require("features.common.ui")
local diagram_utils = require("ui.diagram_utils")

local ns_id_follow = utils.create_namespace("AlloyPipelineFollow")
local ns_id_dim = utils.create_namespace("AlloyPipelineDim")

function M.follow_from_diagram()
	local current_state = state.get_state()
	if state.is_syncing() or not current_state or vim.api.nvim_get_current_win() ~= current_state.win_id then
		return
	end
	local source_bufnr = current_state.source_bufnr
	local _, current_box =
		diagram_utils.get_box_at_cursor(current_state.win_id, current_state.box_metadata, current_state.type)
	vim.api.nvim_buf_clear_namespace(current_state.buf, ns_id_follow, 0, -1)
	if current_box then
		if current_state.type == "vertical_list" then
			vim.api.nvim_buf_add_highlight(
				current_state.buf,
				ns_id_follow,
				"DiagramBoxFollow",
				current_box.line_in_diagram - 1,
				0,
				-1
			)
		else
			for i = 0, 3 do
				vim.api.nvim_buf_add_highlight(
					current_state.buf,
					ns_id_follow,
					"DiagramBoxFollow",
					current_box.line_in_diagram - 1 + i,
					0,
					-1
				)
			end
		end
		local source_win_id = vim.fn.bufwinid(source_bufnr)
		if source_win_id ~= -1 then
			state.set_syncing(true)
			local original_scrolloff = vim.api.nvim_win_get_option(source_win_id, "scrolloff")
			vim.api.nvim_win_set_option(source_win_id, "scrolloff", 0)
			vim.api.nvim_win_set_cursor(source_win_id, { current_box.source_line, 0 })
			vim.fn.win_execute(source_win_id, "normal! zt")
			vim.api.nvim_win_set_option(source_win_id, "scrolloff", original_scrolloff)
			state.set_syncing(false)
		end
	end
	if not current_box then
		vim.api.nvim_buf_clear_namespace(source_bufnr, ns_id_dim, 0, -1)
		ui.close_component_popup()
		return
	end
	vim.api.nvim_buf_clear_namespace(source_bufnr, ns_id_dim, 0, -1)
	local components, _, _ = parser.get_parsed_pipeline_data(source_bufnr)
	if not components then
		return
	end
	local current_key = current_box.key
	for key, comp_data in pairs(components) do
		if key ~= current_key then
			for line_num = comp_data.line - 1, comp_data.end_line - 1 do
				vim.api.nvim_buf_add_highlight(source_bufnr, ns_id_dim, "DiagramDimmedText", line_num, 0, -1)
			end
		end
	end
	ui.close_component_popup()
end

return M