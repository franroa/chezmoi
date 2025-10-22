local M = {}

local grafana_manager = require("features.testing.utils.grafana_manager")
local e2e_runner = require("features.testing.utils.e2e_runner")
local popup = require("ui.popup")

function M.show_grafana_logs()
	local container_id = grafana_manager.get_grafana_url() and "grafana-alloy-test" or nil
	if not container_id then
		vim.notify("Grafana container not found", vim.log.levels.WARN)
		return
	end
	
	local logs = vim.fn.system("docker logs " .. container_id .. " 2>&1 | tail -n 100")
	local lines = vim.split(logs, "\n")
	
	popup.create_popup(lines, {
		title = "Grafana Logs",
		filetype = "log",
		border = "rounded"
	})
end

function M.show_loki_logs()
	local logs = vim.fn.system("docker logs neovim-loki-test 2>&1 | tail -n 100")
	local lines = vim.split(logs, "\n")
	
	popup.create_popup(lines, {
		title = "Loki Logs",
		filetype = "log",
		border = "rounded"
	})
end

function M.show_mimir_logs()
	local logs = vim.fn.system("docker logs neovim-mimir-test 2>&1 | tail -n 100")
	local lines = vim.split(logs, "\n")
	
	popup.create_popup(lines, {
		title = "Mimir Logs",
		filetype = "log",
		border = "rounded"
	})
end

function M.show_alloy_logs()
	local pid = e2e_runner.state.alloy_pid
	if not pid then
		vim.notify("Alloy is not running", vim.log.levels.WARN)
		return
	end
	
	local logs = vim.fn.system("journalctl --since '1 hour ago' | grep alloy | tail -n 100")
	if logs == "" then
		logs = "No recent Alloy logs found in systemd journal"
	end
	
	local lines = vim.split(logs, "\n")
	
	popup.create_popup(lines, {
		title = "Alloy Logs",
		filetype = "log",
		border = "rounded"
	})
end

return M