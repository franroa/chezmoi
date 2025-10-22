local M = {}

local state = require("features.common.state")
local diagram_utils = require("ui.diagram_utils")
local tester = require("features.testing.utils.e2e_runner")

function M.run_pipeline_test_from_diagram()
	local current_state = state.get_state()
	if not (current_state and current_state.source_bufnr) then
		vim.notify("Error: Could not find source buffer for the diagram.", vim.log.levels.ERROR)
		return
	end
	local _, box =
		diagram_utils.get_box_at_cursor(current_state.win_id, current_state.box_metadata, current_state.type)
	if not box then
		vim.notify("Cursor is not on a component box.", vim.log.levels.WARN)
		return
	end
	local component_key = box.key
	local pipelines = current_state.pipelines
	local relevant_pipelines = vim.tbl_filter(function(chain)
		return vim.tbl_contains(chain, component_key)
	end, pipelines)

	if #relevant_pipelines == 0 then
		vim.notify("Could not find a pipeline for the current component.", vim.log.levels.WARN)
		return
	end

	local components_to_test = {}
	for _, key in ipairs(relevant_pipelines[1]) do
		table.insert(components_to_test, current_state.components[key])
	end

	tester.run({
		source_bufnr = current_state.source_bufnr,
		pipeline_components = components_to_test,
	})
end

return M