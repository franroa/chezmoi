local M = {}

local utils = require("core.utils")

-- Store Grafana state
local state = {
	container_id = nil,
	port = nil,
}

-- Detect if running in WSL
local function is_wsl()
	local output = vim.fn.system("uname -r")
	return output:lower():match("microsoft") ~= nil or output:lower():match("wsl") ~= nil
end

-- Get WSL IP address
local function get_wsl_ip()
	local ip = vim.fn.system("ip addr show eth0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'"):gsub("%s+", "")
	if ip == "" then
		-- Try another common interface name
		ip = vim.fn.system("ip addr show bond0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'"):gsub("%s+", "")
	end
	return ip
end

-- Generate a Grafana datasource provisioning file for the specified backend
local function create_datasource_config(backend_type, backend_url, logger)
	local temp_dir = vim.fn.tempname()
	vim.fn.mkdir(temp_dir .. "/provisioning/datasources", "p")

	-- Adjust backend URL for WSL if needed
	local adjusted_backend_url = backend_url
	if is_wsl() then
		-- Replace localhost with WSL IP address
		local wsl_ip = get_wsl_ip()
		if wsl_ip ~= "" then
			-- Replace localhost or 127.0.0.1 with the WSL IP
			adjusted_backend_url = backend_url:gsub("localhost", wsl_ip):gsub("127.0.0.1", wsl_ip)
			if logger then
				logger.info("WSL detected. Adjusted backend URL: " .. adjusted_backend_url)
			end
		else
			if logger then
				logger.error("WSL detected but couldn't determine IP address. Using original backend URL.")
			end
		end
	end

	local datasource_content
	if backend_type == "loki" then
		datasource_content = [[
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: ]] .. adjusted_backend_url .. [[

    isDefault: true
    editable: true
]]
	else -- mimir
		-- Important: With Mimir's API prefix configuration, we need to include the /prometheus prefix
		-- in the datasource URL as that's where the Prometheus API is exposed
		datasource_content = [[
apiVersion: 1

datasources:
  - name: Mimir
    type: prometheus
    access: proxy
    url: ]] .. adjusted_backend_url .. [[/prometheus
    
    isDefault: true
    editable: true
    jsonData:
      prometheusType: Mimir
      prometheusVersion: 2.40.0
      timeInterval: "15s"
      httpHeaderName1: "X-Scope-OrgID"
    secureJsonData:
      httpHeaderValue1: "fake"
]]
	end

	local config_file = temp_dir .. "/provisioning/datasources/datasource.yaml"
	vim.fn.writefile(vim.split(datasource_content, "\n"), config_file)
	return temp_dir
end

-- Start Grafana container with proper configuration
function M.start_grafana(backend_type, backend_url, on_ready, logger)
	-- First check if docker is available
	local docker_check = vim.fn.system("docker --version")
	if vim.v.shell_error ~= 0 then
		logger.error("Docker is not available. Cannot start Grafana container.")
		if on_ready then
			on_ready(false)
		end
		return
	end

	logger.step("SETTING UP GRAFANA")

	-- Get a free port for Grafana
	state.port = utils.get_free_port()
	if not state.port then
		logger.error("Could not find a free port for Grafana.")
		if on_ready then
			on_ready(false)
		end
		return
	end

	-- WSL detection and warning
	if is_wsl() then
		logger.info("WSL detected - adjusting network configuration for WSL compatibility")
		logger.info("To access Grafana from Windows, use the WSL IP instead of localhost")

		local wsl_ip = get_wsl_ip()
		if wsl_ip ~= "" then
			logger.info("Your WSL IP is: " .. wsl_ip)
			logger.info("Access Grafana at: http://" .. wsl_ip .. ":" .. state.port)
		end
	end

	-- Create datasource configuration
	local config_dir = create_datasource_config(backend_type, backend_url, logger)

	-- Start Grafana container
	local docker_cmd = {
		"docker",
		"run",
		"--rm",
		"-d",
		"-p",
		state.port .. ":3000",
		"-v",
		config_dir .. "/provisioning:/etc/grafana/provisioning",
		"-e",
		"GF_AUTH_ANONYMOUS_ENABLED=true",
		"-e",
		"GF_AUTH_ANONYMOUS_ORG_ROLE=Admin",
		"-e",
		"GF_AUTH_DISABLE_LOGIN_FORM=true",
		"-e",
		"GF_FEATURE_TOGGLES_ENABLE=publicDashboards",
		"--name",
		"alloy_test_grafana_" .. os.time(),
		"grafana/grafana:latest",
	}

	logger.info("Starting Grafana container with command:")
	logger.code(table.concat(docker_cmd, " "))

	local docker_output = vim.fn.system(docker_cmd)
	if vim.v.shell_error ~= 0 then
		logger.error("Failed to start Grafana container: " .. docker_output)
		if on_ready then
			on_ready(false)
		end
		return
	end

	-- Get container ID
	state.container_id = vim.fn.trim(docker_output)
	logger.success("Started Grafana container with ID: " .. state.container_id)

	-- Wait for Grafana to be ready (check health endpoint)
	logger.info("Waiting for Grafana to be ready...")

	-- Function to check if Grafana is ready
	local function check_grafana_ready()
		local health_url = "http://localhost:" .. state.port .. "/api/health"
		local health_check = vim.fn.system("curl -s --max-time 3 --connect-timeout 3 " .. health_url)
		
		-- Check if curl succeeded and we got a valid JSON response
		if vim.v.shell_error == 0 and health_check:match('{".*}') then
			-- Look for any sign that Grafana is running (database ok, or version info)
			if health_check:find('"database"') or health_check:find('"version"') then
				logger.success("✅ Grafana is ready!")
				if on_ready then
					on_ready(true)
				end
				return true
			end
		end
		return false
	end

	-- Give Grafana a moment to start up before first check
	local check_attempts = 0
	local max_attempts = 30
	local timer = vim.loop.new_timer()

	timer:start(
		2000, -- Wait 2 seconds before first check
		1000, -- Then check every 1 second
		vim.schedule_wrap(function()
			check_attempts = check_attempts + 1

			if check_grafana_ready() then
				timer:stop()
				return
			end

			if check_attempts >= max_attempts then
				logger.error("Grafana did not become ready after " .. max_attempts .. " attempts.")
				timer:stop()
				if on_ready then
					on_ready(false)
				end
			end
		end)
	)
end

-- Stop Grafana container
function M.stop_grafana(logger)
	if state.container_id then
		logger.info("Stopping Grafana container: " .. state.container_id)
		local output = vim.fn.system("docker stop " .. state.container_id)
		if vim.v.shell_error ~= 0 then
			logger.error("Failed to stop Grafana container: " .. output)
		else
			logger.success("Grafana container stopped successfully.")
		end
		state.container_id = nil
	end
end

-- Get Grafana URL
function M.get_grafana_url()
	if state.port then
		return "http://localhost:" .. state.port
	end
	return nil
end

-- Check if Grafana is running
function M.is_running()
	return state.container_id ~= nil
end

return M

