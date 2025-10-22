local M = {}

local utils = require("core.utils")
local parser = require("core.parser")
local tester = require("features.testing.utils.e2e_runner")

local ns_id_override_icon = utils.create_namespace("AlloyOverrideIcon")

function M.show_override_icons_in_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	tester.update_override_state()
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id_override_icon, 0, -1)
	local components, _, _ = parser.get_parsed_pipeline_data(bufnr)
	if not components then
		return
	end
	for _, comp_data in pairs(components) do
		local override_key = comp_data.type .. "-" .. comp_data.label
		if utils.overridden_components[override_key] then
			vim.api.nvim_buf_set_extmark(
				bufnr,
				ns_id_override_icon,
				comp_data.line - 1,
				-1,
				{ virt_text = { { " 🧪", "AlloyOverrideIcon" } }, virt_text_pos = "eol" }
			)
		end
	end
end

return M