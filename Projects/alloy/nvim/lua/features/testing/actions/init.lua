local M = {}

-- Import all action modules
local edit_override = require("features.testing.actions.edit_override")
local run = require("features.testing.actions.run")
local rerun = require("features.testing.actions.rerun")
local toggle_summary = require("features.testing.actions.toggle_summary")
local toggle_test_log_window = require("features.testing.actions.toggle_test_log_window")
local run_pipeline_test = require("features.testing.actions.run_pipeline_test")
local setup_test_env = require("features.testing.actions.setup_test_env")
local open_urls = require("features.testing.actions.open_urls")
local show_logs = require("features.testing.actions.show_logs")

-- Export all functions from the modules
M.edit_override_file = edit_override.edit_override_file
M.run_pipeline_test = run_pipeline_test.run_pipeline_test
M.run = run.run
M.rerun = rerun.rerun
M.toggle_summary = toggle_summary.toggle_summary
M.toggle_test_log_window = toggle_test_log_window.toggle_test_log_window
M.setup_test_env = setup_test_env.setup_test_env

-- URL opening actions
M.open_grafana_url = open_urls.open_grafana_url
M.open_loki_url = open_urls.open_loki_url
M.open_mimir_url = open_urls.open_mimir_url
M.open_alloy_url = open_urls.open_alloy_url

-- Log viewing actions
M.show_grafana_logs = show_logs.show_grafana_logs
M.show_loki_logs = show_logs.show_loki_logs
M.show_mimir_logs = show_logs.show_mimir_logs
M.show_alloy_logs = show_logs.show_alloy_logs

-- Connect modules that need to reference each other
rerun.run_function = run.run
run_pipeline_test.run_function = run.run

-- Initialize modules
local e2e_runner = require("features.testing.utils.e2e_runner")

-- Create a cleanup function that refers to e2e_runner
M.cleanup = e2e_runner.cleanup

return M
