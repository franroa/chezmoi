local utils = require("core.utils")
local parser = require("core.parser")
local state = require("features.common.state")
local diagram_utils = require("ui.diagram_utils")

local M = {}

function M.edit_override_file()
	local component_type, component_label
	local current_state = state.get_state()

	if
		current_state
		and utils.validate_window(current_state.win_id)
		and vim.api.nvim_get_current_win() == current_state.win_id
	then
		local _, box =
			diagram_utils.get_box_at_cursor(current_state.win_id, current_state.box_metadata, current_state.type)
		if box then
			component_type = box.original_type
			component_label = box.original_label
		else
			utils.notify_with_context("Cursor is not on a component box.", vim.log.levels.WARN, "Override")
			return
		end
	else
		local current_buf = vim.api.nvim_get_current_buf()
		local components, _, _ = parser.get_parsed_pipeline_data(current_buf)
		if not components then
			utils.notify_with_context(
				"Could not parse Alloy components in this buffer.",
				vim.log.levels.WARN,
				"Override"
			)
			return
		end

		local _, comp_data = utils.get_cursor_component(current_buf, components)
		if not comp_data then
			utils.notify_with_context(
				"Cursor is not inside a recognized component block.",
				vim.log.levels.INFO,
				"Override"
			)
			return
		end

		component_type = comp_data.type
		component_label = comp_data.label
	end

	if not (component_type and component_label) then
		utils.notify_with_context("Could not identify component.", vim.log.levels.ERROR, "Override")
		return
	end
	local override_key = component_type .. "-" .. component_label
	local override_dir = vim.fn.getcwd() .. "/.alloy_tests/" .. override_key
	local override_file = override_dir .. "/localtest.alloy"

	if vim.fn.filereadable(override_file) == 1 then
		vim.cmd("vsplit " .. vim.fn.fnameescape(override_file))
	else
		vim.notify("No override file found for " .. override_key, vim.log.levels.INFO)
		vim.ui.input({ prompt = "Override file not found. Create it? (y/n)", default = "y" }, function(input)
			if input and input:lower() == "y" then
				vim.fn.mkdir(override_dir, "p")
				local boilerplate = {
					component_type .. ' "' .. component_label .. '" {',
					"  ",
					"}",
				}
				vim.fn.writefile(boilerplate, override_file)
				vim.cmd("vsplit " .. vim.fn.fnameescape(override_file))
			end
		end)
	end
end

return M
