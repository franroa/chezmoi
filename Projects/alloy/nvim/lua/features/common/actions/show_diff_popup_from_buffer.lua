local M = {}

local utils = require("core.utils")
local parser = require("core.parser")
local tester = require("features.testing.utils.e2e_runner")
local ui = require("features.common.ui")

function M.show_diff_popup_from_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	tester.update_override_state()
	local components, _, _ = parser.get_parsed_pipeline_data(bufnr)
	if not components then
		return
	end
	local found_component = nil
	for _, comp_data in pairs(components) do
		if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
			found_component = comp_data
			break
		end
	end
	if not found_component then
		return
	end
	local override_key = found_component.type .. "-" .. found_component.label
	if utils.overridden_components[override_key] then
		local box_data = {
			original_type = found_component.type,
			original_label = found_component.label,
			is_overridden = true,
			original_block_content = found_component.original_block_content,
		}
		ui.open_component_popup(box_data, {})
	else
		-- no override
	end
end

return M