local M = {}

local testing = require("features.testing")

function M.run()
  return testing.run()
end

function M.run_pipeline_test()
  return testing.run_pipeline_test()
end

function M.rerun()
  return testing.rerun()
end

function M.toggle_log()
  return testing.toggle_test_log_window()
end

function M.toggle_summary()
  return testing.toggle_summary()
end

return M