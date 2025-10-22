--- Health checks for the Alloy plugin.
---
--- This module provides health checks that can be run via :checkhealth alloy

local M = {}

local configuration = require("main._core.configuration")

--- Check if external dependencies are available
--@return boolean
local function check_external_dependencies()
	local deps = {
		{ name = "docker", cmd = "docker --version", desc = "Docker for managing Loki container" },
		{ name = "curl", cmd = "curl --version", desc = "cURL for HTTP requests to Loki" },
		{ name = "alloy", cmd = "alloy --version", desc = "Alloy binary for E2E testing" },
	}

	local all_ok = true

	for _, dep in ipairs(deps) do
		local handle = io.popen(dep.cmd .. " 2>/dev/null")
		if handle then
			local result = handle:read("*a")
			handle:close()

			if result and result ~= "" then
				vim.health.ok(dep.name .. " is available")
			else
				vim.health.warn(dep.name .. " is not available", dep.desc)
				all_ok = false
			end
		else
			vim.health.error("Could not check " .. dep.name, dep.desc)
			all_ok = false
		end
	end

	return all_ok
end

--- Check configuration validity
--@return boolean
local function check_configuration()
	local ok, err = pcall(function()
		configuration.initialize_data_if_needed()
		local config = configuration.DATA

		-- Check required string fields
		local string_fields = {
			"loki_url",
			"loki_container_name",
			"loki_image",
			"override_dir_name",
			"override_file_name",
		}

		for _, field in ipairs(string_fields) do
			if type(config[field]) ~= "string" or config[field] == "" then
				error("Invalid " .. field .. ": expected non-empty string, got " .. type(config[field]))
			end
		end

		-- Check boolean fields
		local bool_fields = { "manage_loki", "debug" }
		for _, field in ipairs(bool_fields) do
			if type(config[field]) ~= "boolean" then
				error("Invalid " .. field .. ": expected boolean, got " .. type(config[field]))
			end
		end

		-- Check URL format
		if not config.loki_url:match("^https?://") then
			error("Invalid loki_url: must be a valid HTTP/HTTPS URL")
		end

		return true
	end)

	if ok then
		vim.health.ok("Configuration is valid")
		return true
	else
		vim.health.error("Configuration validation failed", err)
		return false
	end
end

--- Check plugin initialization
--@return boolean
local function check_initialization()
	if vim.g.loaded_alloy then
		vim.health.ok("Plugin is properly initialized")
		return true
	else
		vim.health.warn("Plugin not yet initialized", "Will initialize on first use")
		return false
	end
end

--- Check if Loki is accessible (if manage_loki is false)
--@return boolean
local function check_loki_connectivity()
	local config = configuration.DATA
	if config.manage_loki then
		vim.health.info("Loki management enabled - will manage container automatically")
		return true
	end

	local loki_url = config.loki_url
	local handle = io.popen("curl -s -o /dev/null -w '%{http_code}' " .. loki_url .. "/ready 2>/dev/null")
	if not handle then
		vim.health.warn("Could not check Loki connectivity", "curl command failed")
		return false
	end

	local result = handle:read("*a")
	handle:close()

	if result == "200" then
		vim.health.ok("Loki is accessible at " .. loki_url)
		return true
	else
		vim.health.warn(
			"Loki is not accessible at " .. loki_url,
			"Expected HTTP 200, got " .. (result or "no response")
		)
		return false
	end
end

--- Check if feature modules are loadable
--@return boolean
local function check_feature_modules()
	local features = {
		{ name = "testing", module = "features.testing" },
		{ name = "visualizer", module = "features.vertical. },
	}

	local all_ok = true

	for _, feature in ipairs(features) do
		local ok, err = pcall(require, feature.module)
		if ok then
			vim.health.ok(feature.name .. " feature is loadable")
		else
			vim.health.error(feature.name .. " feature failed to load", err)
			all_ok = false
		end
	end

	return all_ok
end

--- Check for common configuration issues
--@return boolean
local function check_common_issues()
	local config = configuration.DATA
	local all_ok = true

	-- Check if override directory exists or can be created
	local cwd = vim.fn.getcwd()
	local override_path = cwd .. "/" .. config.override_dir_name

	local stat = vim.loop.fs_stat(override_path)
	if stat then
		if stat.type == "directory" then
			vim.health.ok("Override directory exists at " .. override_path)
		else
			vim.health.warn("Override path exists but is not a directory", override_path)
			all_ok = false
		end
	else
		vim.health.info("Override directory will be created at " .. override_path)
	end

	return all_ok
end

--- Main health check function
function M.check()
	vim.health.start("Alloy Plugin Health Check")

	-- Initialize if not already done
	configuration.initialize_data_if_needed()

	local checks = {
		{ name = "Plugin Initialization", func = check_initialization },
		{ name = "Configuration Validation", func = check_configuration },
		{ name = "External Dependencies", func = check_external_dependencies },
		{ name = "Feature Modules", func = check_feature_modules },
		{ name = "Loki Connectivity", func = check_loki_connectivity },
		{ name = "Common Issues", func = check_common_issues },
	}

	local overall_ok = true

	for _, check in ipairs(checks) do
		vim.health.start(check.name)
		local ok = check.func()
		if not ok then
			overall_ok = false
		end
	end

	-- Show current configuration for debugging
	vim.health.start("Current Configuration")
	local data = configuration.DATA
	vim.health.info("  Loki URL: " .. data.loki_url)
	vim.health.info("  Manage Loki: " .. tostring(data.manage_loki))
	vim.health.info("  Debug mode: " .. tostring(data.debug))
	vim.health.info("  Override directory: " .. data.override_dir_name)

	if overall_ok then
		vim.health.start("Overall Status")
		vim.health.ok("All checks passed - Alloy plugin is ready to use")
	else
		vim.health.start("Overall Status")
		vim.health.warn("Some checks failed - plugin may not work correctly")
	end
end

return M
