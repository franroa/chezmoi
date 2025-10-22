local M = {}

local state = require("features.common.state")
local ui = require("features.common.ui")
local diagram_utils = require("ui.diagram_utils")
local tester = require("features.testing.utils.e2e_runner")
local utils = require("core.utils")

function M.go_to_definition()
	local current_state = state.get_state()
	local _, box =
		diagram_utils.get_box_at_cursor(current_state.win_id, current_state.box_metadata, current_state.type)
	if not box then
		return
	end
	if utils.last_summary_data and not utils.last_summary_data.test_passed then
		tester.toggle_summary()
		return
	end
	local source_win_id = vim.fn.bufwinid(current_state.source_bufnr)
	vim.api.nvim_win_close(current_state.win_id, true)
	if source_win_id ~= -1 then
		vim.api.nvim_set_current_win(source_win_id)
	end
	vim.api.nvim_win_set_cursor(0, { box.source_line, 0 })
end

return M