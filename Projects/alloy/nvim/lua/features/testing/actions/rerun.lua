local e2e_runner = require("features.testing.utils.e2e_runner")

local M = {}

-- Need to be set from init.lua
M.run_function = nil

function M.rerun()
	local logger = e2e_runner.create_logger()
	if not e2e_runner.state.last_alloy_config_content then
		logger.error("No previous test configuration found to rerun.")
		return
	end
	if not e2e_runner.state.last_source_bufnr or not vim.api.nvim_buf_is_valid(e2e_runner.state.last_source_bufnr) then
		logger.error("Cannot rerun test, the original source buffer was closed.")
		return
	end
	logger.info("Rerunning the last test with the same configuration...")
	if M.run_function then
		return M.run_function({ rerun = true, source_bufnr = e2e_runner.state.last_source_bufnr })
	else
		logger.error("Run function not properly initialized.")
	end
end

return M
