local M = {}

local integration_state = require("core.alloy_integration_state")
local loki_manager = require("features.testing.utils.loki_manager")
local mimir_manager = require("features.testing.utils.mimir_manager")
local block_overrides = require("features.testing.utils.block_overrides")
local log_window = require("ui.log_window")
local test_summary = require("ui.test_summary")

local ns_id_pipeline_test_hl = vim.api.nvim_create_namespace("AlloyTestedPipeline")

-- Make config accessible
M.config = {
	override_dir_name = ".alloy_tests",
}

-- Make state accessible
M.state = {
	test_dir = nil,
	alloy_data_dir = nil,
	alloy_pid = nil,
	alloy_port = nil,
	last_summary_data = nil,
	summary_win_id = nil,
	last_alloy_config_content = nil,
	last_source_bufnr = nil,
	backend_type = "loki", -- 'loki' or 'mimir'
}

-- Make create_logger accessible
function M.create_logger()
	return {
		info = function(msg)
			log_window.log_message("[INFO] " .. msg, "Comment")
		end,
		success = function(msg)
			log_window.log_message("[SUCCESS] " .. msg, "String")
		end,
		error = function(msg)
			log_window.log_message("[ERROR] " .. msg, "ErrorMsg")
		end,
		step = function(msg)
			log_window.log_message("\n--- " .. msg .. " ---", "Title")
		end,
		code = function(msg)
			log_window.log_message(msg, "Constant")
		end,
		alloy_log = function(msg)
			log_window.log_message("[ALLOY LOG] " .. msg, "Debug")
		end,
	}
end

function M.cleanup()
	integration_state.notify_debug("Cleanup started.")
	local logger = M.create_logger()
	logger.info("Cleaning up...")

	-- Stop Grafana if it's running
	local grafana_manager = require("features.testing.utils.grafana_manager")
	if grafana_manager.is_running() then
		grafana_manager.stop_grafana(logger)
	end

	if M.state.alloy_pid then
		pcall(vim.loop.kill, M.state.alloy_pid, "SIGTERM")
		M.state.alloy_pid = nil
	end

	if M.state.last_source_bufnr and vim.api.nvim_buf_is_valid(M.state.last_source_bufnr) then
		vim.api.nvim_buf_clear_namespace(M.state.last_source_bufnr, ns_id_pipeline_test_hl, 0, -1)
	end

	if M.state.backend_type == "loki" then
		loki_manager.stop_loki(logger)
	else
		mimir_manager.stop_mimir(logger)
	end

	if M.state.test_dir and vim.fn.isdirectory(M.state.test_dir) == 1 then
		logger.info("Removing test directory: " .. M.state.test_dir)
		pcall(vim.fn.delete, M.state.test_dir, "rf")
	end
	if M.state.alloy_data_dir and vim.fn.isdirectory(M.state.alloy_data_dir) == 1 then
		logger.info("Removing Alloy data directory: " .. M.state.alloy_data_dir)
		pcall(vim.fn.delete, M.state.alloy_data_dir, "rf")
		M.state.alloy_data_dir = nil
	end

	integration_state.overridden_components = {}
	integration_state.last_summary_data = nil

	logger.info("Cleanup complete.")
	integration_state.notify_debug("Cleanup finished.")
end

function M.toggle_summary()
	if M.state.summary_win_id and vim.api.nvim_win_is_valid(M.state.summary_win_id) then
		vim.api.nvim_win_close(M.state.summary_win_id, true)
		M.state.summary_win_id = nil
	elseif M.state.last_summary_data then
		M.state.summary_win_id = test_summary.show_summary(M.state.last_summary_data)
	else
		local logger = M.create_logger()
		logger.info("No test summary available. Run the test first.")
	end
end

function M.toggle_test_log_window()
	log_window.toggle_test_log_window()
end

function M.get_override_content(component_key)
	return block_overrides.get_override_content(component_key, M.config.override_dir_name)
end

function M.update_override_state()
	block_overrides.update_override_state(M.config.override_dir_name)
end

-- Remove the setup function from here as it's been moved to keymaps.lua
-- Export the namespace ID for pipeline test highlighting
M.ns_id_pipeline_test_hl = ns_id_pipeline_test_hl

return M
