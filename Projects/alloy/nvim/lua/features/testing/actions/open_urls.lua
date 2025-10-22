local M = {}

local utils = require("core.utils")
local grafana_manager = require("features.testing.utils.grafana_manager")
local loki_manager = require("features.testing.utils.loki_manager")
local mimir_manager = require("features.testing.utils.mimir_manager")
local e2e_runner = require("features.testing.utils.e2e_runner")

function M.open_grafana_url()
	local url = grafana_manager.get_grafana_url()
	utils.open_url_in_browser(url, "Grafana")
end

function M.open_loki_url()
	local url = loki_manager.get_loki_url()
	utils.open_url_in_browser(url, "Loki")
end

function M.open_mimir_url()
	local url = mimir_manager.get_mimir_url()
	utils.open_url_in_browser(url, "Mimir")
end

function M.open_alloy_url()
	local port = e2e_runner.state.alloy_port
	local url = port and ("http://localhost:" .. port) or nil
	utils.open_url_in_browser(url, "Alloy")
end

return M