local e2e_runner = require("features.testing.utils.e2e_runner")
local test_summary = require("ui.test_summary")

local M = {}

function M.toggle_summary()
	if e2e_runner.state.summary_win_id and vim.api.nvim_win_is_valid(e2e_runner.state.summary_win_id) then
		vim.api.nvim_win_close(e2e_runner.state.summary_win_id, true)
		e2e_runner.state.summary_win_id = nil
	elseif e2e_runner.state.last_summary_data then
		e2e_runner.state.summary_win_id = test_summary.show_summary(e2e_runner.state.last_summary_data)
	else
		local logger = e2e_runner.create_logger()
		logger.info("No test summary available. Run the test first.")
	end
end

return M
