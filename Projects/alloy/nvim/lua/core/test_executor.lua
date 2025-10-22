local M = {}

-- thin adapter to features.testing.test_executor
local feat = require("features.testing.utils.test_executor")

function M.run_from_dir(test_dir, opts)
	opts = opts or {}
	-- features.testing.test_executor.execute_query_and_verify requires (test_dir, query_url_base, override_dir_name, logger, backend_type, on_complete)
	local logger = require("features.testing.utils.e2e_runner").create_logger()
	local override_dir_name = ".alloy_tests"
	local backend_type = require("features.testing.utils.e2e_runner")._state.backend_type
	local query_url_base = backend_type == "loki" and string.format("http://localhost:%d", 3100)
		or string.format("http://localhost:%d", 9090)
	feat.execute_query_and_verify(test_dir, query_url_base, override_dir_name, logger, backend_type, function(summary)
		require("features.testing.utils.e2e_runner")._state.last_summary_data = summary
	end)
end

return M
