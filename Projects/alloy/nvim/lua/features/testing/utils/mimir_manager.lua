local M = {}

local config = {
	mimir_url = "http://localhost:9009",
	manage_mimir = true,
	mimir_container_name = "neovim-mimir-test",
	mimir_image = "grafana/mimir:2.17.0",
}

local state = {
	mimir_started_by_script = false,
}

local function wait_for_service(name, url, callback, logger)
	logger.info(string.format("Waiting for %s to be ready at %s...", name, url))
	local timer = vim.loop.new_timer()
	local poll_count = 0

	-- Using both /ready and /metrics endpoints for more reliable checks
	local endpoints = {
		ready = url .. "/ready",
		metrics = url .. "/metrics",
		root = url .. "/",
	}

	logger.info("Will check these endpoints: " .. vim.inspect(endpoints))

	local poll = vim.schedule_wrap(function()
		poll_count = poll_count + 1
		-- Timeout increased to 2 minutes (240 * 500ms)
		if poll_count > 240 then
			timer:stop()
			logger.error(string.format("Timeout waiting for %s.", name))

			-- Try to get container logs to diagnose the issue
			if name == "Mimir" then
				logger.error("Fetching Mimir container logs to diagnose readiness issue...")
				local logs = vim.fn.system("docker logs " .. config.mimir_container_name .. " 2>&1 | tail -n 50")
				logger.error("Mimir container logs (last 50 lines):")
				logger.code(logs)

				-- Try direct curl to see what's happening
				for endpoint_name, endpoint_url in pairs(endpoints) do
					logger.info("Testing endpoint: " .. endpoint_name)
					local curl_output = vim.fn.system("curl -v " .. endpoint_url .. " 2>&1")
					logger.info("Response from " .. endpoint_name .. ":")
					logger.code(curl_output)
				end
			end

			-- Try to continue despite timeout
			logger.info("Attempting to continue despite readiness timeout...")
			callback()
			return
		end

		-- Try the ready endpoint first
		vim.fn.jobstart({ "curl", "--output", "/dev/null", "--silent", "--fail", endpoints.ready }, {
			on_exit = vim.schedule_wrap(function(_, code)
				if code == 0 then
					timer:stop()
					logger.success(string.format("%s is ready.", name))
					callback()
				else
					-- If /ready fails, try /metrics as backup
					vim.fn.jobstart({ "curl", "--output", "/dev/null", "--silent", "--fail", endpoints.metrics }, {
						on_exit = vim.schedule_wrap(function(_, metrics_code)
							if metrics_code == 0 then
								timer:stop()
								logger.success(string.format("%s is ready (detected via metrics endpoint).", name))
								callback()
							end
							-- If both fail, will retry on next poll
						end),
					})
				end
			end),
		})
	end)

	timer:start(0, 500, poll)
end

-- Test different API endpoints to determine the correct URL structure
local function test_mimir_endpoints(logger)
	logger.info("Testing Mimir API endpoints to determine correct URL structure...")

	local function test_endpoint(endpoint, description)
		local url = config.mimir_url .. endpoint
		logger.info("Testing " .. description .. " at: " .. url)

		local cmd = { "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", url }
		local output = vim.fn.system(cmd)
		local status_code = tonumber(output:match("^%s*(.-)%s*$")) -- Trim and convert to number

		logger.info("Result: " .. endpoint .. " returned status code: " .. (status_code or "unknown"))
		return status_code
	end

	-- Test various possible endpoint configurations
	local endpoints = {
		["/"] = "Root endpoint",
		["/ready"] = "Ready endpoint",
		["/metrics"] = "Metrics endpoint",
		["/api/v1/query"] = "Direct Prometheus API",
		["/prometheus/api/v1/query"] = "Prometheus API with prefix",
		["/prometheus"] = "Prometheus prefix endpoint",
	}

	for endpoint, description in pairs(endpoints) do
		test_endpoint(endpoint, description)
	end
end

local function start_or_recreate_mimir_container(on_ready_callback, logger, test_dir)
	logger.step("1. PREPARING MIMIR CONTAINER")
	if vim.fn.executable("docker") ~= 1 then
		logger.error("`docker` command not found. Cannot start Mimir.")
		return false
	end

	-- Create a clean Mimir config file from scratch
	local mimir_config_path = test_dir .. "/mimir.yaml"
	local mimir_config_content = {
		"# Do not use this configuration in production.",
		"# It is for demonstration purposes only.",
		"multitenancy_enabled: false",
		"",
		"blocks_storage:",
		"  backend: filesystem",
		"  bucket_store:",
		"    sync_dir: /tmp/mimir/tsdb-sync",
		"  filesystem:",
		"    dir: /tmp/mimir/data/tsdb",
		"  tsdb:",
		"    dir: /tmp/mimir/tsdb",
		"",
		"compactor:",
		"  data_dir: /tmp/mimir/compactor",
		"  sharding_ring:",
		"    kvstore:",
		"      store: memberlist",
		"",
		"distributor:",
		"  ring:",
		"    instance_addr: 127.0.0.1",
		"    kvstore:",
		"      store: memberlist",
		"",
		"ingester:",
		"  ring:",
		"    instance_addr: 127.0.0.1",
		"    kvstore:",
		"      store: memberlist",
		"    replication_factor: 1",
		"",
		"ruler_storage:",
		"  backend: filesystem",
		"  filesystem:",
		"    dir: /tmp/mimir/rules",
		"",
		"server:",
		"  http_listen_port: 9009",
		"  log_level: error",
		"",
		"store_gateway:",
		"  sharding_ring:",
		"    replication_factor: 1",
	}
	vim.fn.writefile(mimir_config_content, mimir_config_path)
	logger.info("Created minimal Mimir config at: " .. mimir_config_path)
	logger.info("Created minimal Mimir config: " .. vim.inspect(mimir_config_content))

	local function run_new_container()
		logger.info("Starting new Mimir container '" .. config.mimir_container_name .. "'...")
		vim.fn.system("mkdir -p " .. test_dir .. "/mimir-blocks")

		local docker_cmd = {
			"docker",
			"run",
			"-d",
			"--rm",
			"--name",
			config.mimir_container_name,
			"-p",
			"9009:9009",
			"-v",
			mimir_config_path .. ":/etc/mimir/mimir.yaml",
			"-v",
			test_dir .. "/mimir-blocks:/tmp/mimir/blocks",
			config.mimir_image,
			"-config.file=/etc/mimir/mimir.yaml",
		}
		logger.code(table.concat(docker_cmd, " "))

		-- Check if Docker image exists, pull if needed
		local image_check = vim.fn.system("docker images -q " .. config.mimir_image)
		if image_check:gsub("%s+", "") == "" then
			logger.info("Mimir image not found locally. Pulling image: " .. config.mimir_image)
			vim.fn.system("docker pull " .. config.mimir_image)
		end

		vim.fn.jobstart(docker_cmd, {
			on_exit = vim.schedule_wrap(function(_, exit_code)
				if exit_code ~= 0 then
					logger.error("Failed to start Mimir container. Exit code: " .. exit_code)
					local logs = vim.fn.system("docker logs " .. config.mimir_container_name .. " 2>&1 | tail -n 50")
					logger.error("Mimir container logs (last 50 lines):")
					logger.code(logs)
					return
				end

				vim.loop.new_timer():start(
					5000, -- Increased to 5s to allow for startup
					0,
					vim.schedule_wrap(function()
						state.mimir_started_by_script = true
						local status = vim.fn.system(
							"docker ps --filter name=" .. config.mimir_container_name .. " --format '{{.Status}}'"
						)
						logger.info("Mimir container status: " .. status)
						wait_for_service("Mimir", config.mimir_url, on_ready_callback, logger)
					end)
				)
			end),
		})
	end

	logger.info("Stopping and removing any previous Mimir test container...")
	-- Use a single command to stop and remove forcefully
	vim.fn.jobstart({ "docker", "rm", "-f", config.mimir_container_name }, {
		on_exit = vim.schedule_wrap(run_new_container),
	})

	return true
end

function M.start_mimir(on_ready_callback, logger, test_dir)
	if config.manage_mimir then
		return start_or_recreate_mimir_container(function()
			-- Test the endpoints to determine the correct URL structure
			vim.loop.new_timer():start(
				3000, -- Give Mimir some time to fully initialize
				0,
				vim.schedule_wrap(function()
					test_mimir_endpoints(logger)
					on_ready_callback()
				end)
			)
		end, logger, test_dir)
	else
		logger.step("5. VERIFYING PRE-EXISTING MIMIR")
		wait_for_service("Mimir", config.mimir_url, function()
			test_mimir_endpoints(logger)
			on_ready_callback()
		end, logger)
		return true
	end
end

function M.stop_mimir(logger)
	if config.manage_mimir and state.mimir_started_by_script then
		logger.info("Stopping Mimir container: " .. config.mimir_container_name)
		vim.fn.jobstart({ "docker", "stop", config.mimir_container_name })
		state.mimir_started_by_script = false
	end
end

function M.get_mimir_url()
	return config.mimir_url
end

function M.wait_for_service(name, url, callback, logger)
	wait_for_service(name, url, callback, logger)
end

function M.set_config(new_config)
	config = vim.tbl_extend("force", config, new_config)
end

return M
