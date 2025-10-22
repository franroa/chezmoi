local M = {}

local utils = require("core.utils")
local parser = require("core.parser")

local function navigate_component(direction)
	local current_buf = vim.api.nvim_get_current_buf()
	local components, _, _ = parser.get_parsed_pipeline_data(current_buf)
	if not components then
		utils.notify_with_context("Could not analyze pipeline.", vim.log.levels.WARN, "Navigation")
		return
	end

	local current_component_key, current_component = utils.get_cursor_component(current_buf, components)
	if not current_component_key then
		utils.notify_with_context(
			"Cursor is not inside a recognized component block.",
			vim.log.levels.INFO,
			"Navigation"
		)
		return
	end

	local targets, message
	if direction == "next" then
		targets = current_component.forward_to
		message = "End of pipeline branch."
	else
		targets = current_component.receives_from
		message = "Start of pipeline branch."
	end

	if not targets or #targets == 0 then
		utils.notify_with_context(message, vim.log.levels.INFO, "Navigation")
		return
	end

	local function do_jump(target_key)
		local target_data = components[target_key]
		if not target_data then
			utils.notify_with_context(
				"Target component '" .. target_key .. "' not found.",
				vim.log.levels.ERROR,
				"Navigation"
			)
			return
		end
		utils.jump_to_line(0, target_data.line, 0)
		vim.cmd("normal! zt")
	end

	if #targets == 1 then
		do_jump(targets[1])
	else
		vim.ui.select(targets, { prompt = "Jump to which component?" }, function(choice)
			if choice then
				do_jump(choice)
			end
		end)
	end
end

function M.jump_to_next_component()
	navigate_component("next")
end

function M.jump_to_previous_component()
	navigate_component("previous")
end

return M