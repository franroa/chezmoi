local M = {}

local utils = require("core.utils")

local ns_id_pipeline_numbers = utils.create_namespace("AlloyPipelineNumbers")

function M.clear_pipeline_numbers()
	vim.g.are_alloy_pipeline_number_shown = false
	vim.api.nvim_buf_clear_namespace(0, ns_id_pipeline_numbers, 0, -1)
	vim.notify("Cleared pipeline icons.", vim.log.levels.INFO)
end

return M