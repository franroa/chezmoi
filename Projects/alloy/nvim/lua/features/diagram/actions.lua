local M = {}

local state = require("features.common.state")
local diagram_utils = require("ui.diagram_utils")

function M.toggle_pipeline_focus()
	local current_state = state.get_state()
	if current_state.type ~= "horizontal" then
		return
	end
	local current_pipeline_idx = diagram_utils.get_current_pipeline_index(current_state)
	if not current_pipeline_idx then
		vim.notify("Cursor not on a valid pipeline component.", vim.log.levels.INFO)
		return
	end
	local start_node_key = current_state.pipelines[current_pipeline_idx][1]
	if current_state.nav_mode == "component" then
		if current_state.container_win_id and vim.api.nvim_win_is_valid(current_state.container_win_id) then
			vim.api.nvim_win_set_height(current_state.container_win_id, current_state.original_container_height)
			vim.api.nvim_win_set_config(
				current_state.win_id,
				{ height = current_state.original_container_height - 2 }
			)
		end
		state.update_state("nav_mode", "pipeline")
		state.update_state("focused_pipeline_index", nil)
		vim.notify("Navigation: Jumping between pipelines", vim.log.levels.INFO)
	else
		local keys_in_group = {}
		for _, chain in ipairs(current_state.pipelines) do
			if #chain > 0 and chain[1] == start_node_key then
				for _, key in ipairs(chain) do
					keys_in_group[key] = true
				end
			end
		end
		local min_line, max_line = 9999, 0
		for _, box in ipairs(current_state.box_metadata) do
			if keys_in_group[box.key] then
				min_line = math.min(min_line, box.line_in_diagram)
				max_line = math.max(max_line, box.line_in_diagram)
			end
		end
		if min_line <= max_line then
			local content_height = (max_line - min_line) + 4
			local new_container_height = content_height + 2
			if current_state.container_win_id and vim.api.nvim_win_is_valid(current_state.container_win_id) then
				vim.api.nvim_win_set_height(current_state.container_win_id, new_container_height)
				vim.api.nvim_win_set_config(current_state.win_id, { height = content_height })
			end
		end
		state.update_state("nav_mode", "component")
		state.update_state("focused_pipeline_index", current_pipeline_idx)
		vim.notify("Pipeline focused. Navigation: Jumping between components.", vim.log.levels.INFO)
	end
	diagram_utils.jump_to_component(current_state, start_node_key)
	vim.schedule(function()
		require("features.common.actions").FollowFromDiagram()
	end)
end

function M.navigate_next()
	local current_state = state.get_state()
	local pipeline_start_boxes = diagram_utils.find_pipeline_start_boxes(current_state)
	if current_state.nav_mode == "component" then
		diagram_utils.navigate_pipeline_components(current_state, "next")
	else
		diagram_utils.navigate_pipeline_starts(current_state, "next", pipeline_start_boxes)
	end
	vim.schedule(function()
		require("features.common.actions").FollowFromDiagram()
	end)
end

function M.navigate_prev()
	local current_state = state.get_state()
	local pipeline_start_boxes = diagram_utils.find_pipeline_start_boxes(current_state)
	if current_state.nav_mode == "component" then
		diagram_utils.navigate_pipeline_components(current_state, "prev")
	else
		diagram_utils.navigate_pipeline_starts(current_state, "prev", pipeline_start_boxes)
	end
	vim.schedule(function()
		require("features.common.actions").FollowFromDiagram()
	end)
end

function M.close_diagram_buffer()
	local current_state = state.get_state()
	vim.api.nvim_win_close(current_state.win_id, true)
end

function M.debug_cursor()
	local current_state = state.get_state()
	diagram_utils.debug_cursor_position(current_state)
end

return M
