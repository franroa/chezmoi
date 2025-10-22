local M = {}

--- Testing specific keymaps
--- Default keybindings are defined in the ACTIONS object below
--- and can be overridden in user configuration
--- Also includes common diagram keymaps via common_keymaps.setup_keymaps()

local state = require("features.common.state")
local keymap_utils = require("core.keymap_utils")
local main_keymaps = require("main.keymaps")
local actions = require("features.testing.actions")

local ACTIONS = {
	["test-toggle-log"] = {
		func = actions.toggle_test_log_window,
		desc = "Toggle Test Log",
		default = { "n", "<leader>tl" },
	},
	["run-e2e-test"] = { func = actions.run, desc = "Run E2E test", default = { "n", "<leader>te" } },
	["rerun-e2e-test"] = { func = actions.rerun, desc = "Rerun E2E test", default = { "n", "<leader>tr" } },
	["run-pipeline-test"] = {
		func = actions.run_pipeline_test,
		desc = "Run pipeline test",
		default = { "n", "<leader>tp" },
	},
	["toggle-summary"] = {
		func = actions.toggle_summary,
		desc = "Toggle test summary",
		default = { "n", "<leader>ts" },
	},
	["setup-test-env"] = {
		func = actions.setup_test_env,
		desc = "Setup test environment only",
		default = { "n", "<leader>tu" },
	},
	["cleanup-test-env"] = {
		func = actions.cleanup,
		desc = "Cleanup test environment",
		default = { "n", "<leader>tc" },
	},
	["open-grafana"] = { func = actions.open_grafana_url, desc = "Open Grafana URL", default = { "n", "<leader>tg" } },
	["open-loki"] = { func = actions.open_loki_url, desc = "Open Loki URL", default = { "n", "<leader>tk" } },
	["open-mimir"] = { func = actions.open_mimir_url, desc = "Open Mimir URL", default = { "n", "<leader>tm" } },
	["open-alloy"] = { func = actions.open_alloy_url, desc = "Open Alloy URL", default = { "n", "<leader>ta" } },
	["show-grafana-logs"] = {
		func = actions.show_grafana_logs,
		desc = "Show Grafana logs",
		default = { "n", "<leader>tG" },
	},
	["show-loki-logs"] = { func = actions.show_loki_logs, desc = "Show Loki logs", default = { "n", "<leader>tK" } },
	["show-mimir-logs"] = { func = actions.show_mimir_logs, desc = "Show Mimir logs", default = { "n", "<leader>tM" } },
	["show-alloy-logs"] = { func = actions.show_alloy_logs, desc = "Show Alloy logs", default = { "n", "<leader>tA" } },
}

function M.setup_keymaps()
	main_keymaps.setup_keymaps()
	local current_state = state.get_state()
	local opts = nil
	if current_state and type(current_state) == "table" and current_state.buf then
		opts = { buffer = current_state.buf, silent = true }
	end
	keymap_utils.setup_default_keymaps(ACTIONS, opts)
end

function M.get_actions()
	return ACTIONS
end

-- Make the register function available through this module as well
M.register = keymap_utils.register

return M
