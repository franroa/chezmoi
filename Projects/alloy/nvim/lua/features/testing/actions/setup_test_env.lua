local utils = require("core.utils")
local parser = require("core.parser")
local loki_manager = require("features.testing.utils.loki_manager")
local mimir_manager = require("features.testing.utils.mimir_manager")
local grafana_manager = require("features.testing.utils.grafana_manager")
local log_window = require("ui.log_window")
local test_executor = require("features.testing.utils.test_executor")
local block_overrides = require("features.testing.utils.block_overrides")
local integration_state = require("core.alloy_integration_state")
local e2e_runner = require("features.testing.utils.e2e_runner")

local M = {}

-- This function is similar to run.lua's start_alloy_and_test but without querying the backend
local function start_alloy_env(logger, opts)
	logger.step("2. SETTING UP ALLOY")
	e2e_runner.state.alloy_port = test_executor.get_free_port()
	if not e2e_runner.state.alloy_port then
		logger.error("Could not find a free port for Alloy.")
		e2e_runner.cleanup()
		return
	end

	local alloy_config_file
	local log_file = e2e_runner.state.test_dir .. "/app.log"
	vim.fn.writefile({}, log_file)

	local placeholders = {
		LOG_FILE_PATH = log_file:gsub("\\", "/"),
		LOKI_URL = loki_manager.get_loki_url(),
		MIMIR_URL = mimir_manager.get_mimir_url() .. "/api/v1/push",
	}

	if opts and opts.rerun then
		alloy_config_file = e2e_runner.state.test_dir .. "/config.alloy"
		logger.info("Using previously generated config content.")
		vim.fn.writefile(e2e_runner.state.last_alloy_config_content, alloy_config_file)
		local lines_for_display = {}
		for _, line in ipairs(e2e_runner.state.last_alloy_config_content) do
			table.insert(lines_for_display, { content = line, type = "unchanged" })
		end
		log_window.print_code_in_box("Using final Alloy configuration (rerun):", lines_for_display)
	elseif opts and opts.pipeline_components then
		logger.info("Preparing single pipeline for test with overrides...")
		local scratch_bufnr = vim.api.nvim_create_buf(false, true)
		local pipeline_content_lines = {}
		for _, component in ipairs(opts.pipeline_components) do
			for _, line in ipairs(vim.split(component.original_block_content, "\n")) do
				table.insert(pipeline_content_lines, line)
			end
			table.insert(pipeline_content_lines, "")
		end
		vim.api.nvim_buf_set_lines(scratch_bufnr, 0, -1, false, pipeline_content_lines)
		logger.info("Scanning for block overrides for the pipeline...")
		local block_overrides_data = block_overrides.load_block_overrides(e2e_runner.config.override_dir_name)
		local final_lines_for_file, final_lines_for_display =
			block_overrides.apply_overrides_to_buffer(scratch_bufnr, block_overrides_data, placeholders, log_window)
		vim.api.nvim_buf_delete(scratch_bufnr, { force = true })
		log_window.print_code_in_box("Using final pipeline configuration:", final_lines_for_display)
		alloy_config_file = e2e_runner.state.test_dir .. "/config.alloy"
		vim.fn.writefile(final_lines_for_file, alloy_config_file)
		e2e_runner.state.last_alloy_config_content = final_lines_for_file
	else
		alloy_config_file = e2e_runner.state.test_dir .. "/config.alloy"
		logger.info("Scanning for block overrides in: " .. e2e_runner.config.override_dir_name)
		local block_overrides_data = block_overrides.load_block_overrides(e2e_runner.config.override_dir_name)
		for key, _ in pairs(block_overrides_data) do
			logger.info(string.format(" - Found block override for '%s'", key))
		end
		local final_lines_for_file, final_lines_for_display = block_overrides.apply_overrides_to_buffer(
			e2e_runner.state.last_source_bufnr,
			block_overrides_data,
			placeholders,
			log_window
		)
		log_window.print_code_in_box("Using final Alloy configuration:", final_lines_for_display)
		vim.fn.writefile(final_lines_for_file, alloy_config_file)
		e2e_runner.state.last_alloy_config_content = final_lines_for_file
	end

	logger.info("Starting Alloy process...")
	local alloy_cmd = {
		"alloy",
		"run",
		"--server.http.listen-addr=0.0.0.0:" .. e2e_runner.state.alloy_port,
		"--storage.path=" .. e2e_runner.state.alloy_data_dir,
		alloy_config_file,
	}
	logger.info("Running command: " .. table.concat(alloy_cmd, " "))
	e2e_runner.state.alloy_pid = vim.fn.jobstart(alloy_cmd, {
		detached = true,
		stdout_buffered = true,
		on_stdout = vim.schedule_wrap(function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						logger.alloy_log(line)
					end
				end
			end
		end),
		stderr_buffered = true,
		on_stderr = vim.schedule_wrap(function(_, data)
			if data then
				logger.error("Alloy process reported an error:")
				for _, line in ipairs(data) do
					for _, sub_line in ipairs(vim.split(line, "\n")) do
						if sub_line ~= "" then
							logger.code(sub_line)
						end
					end
				end
			end
		end),
	})

	if not e2e_runner.state.alloy_pid or e2e_runner.state.alloy_pid <= 0 then
		logger.error("Failed to start the Alloy process.")
		e2e_runner.cleanup()
		return
	end

	logger.step("3. ALLOY TEST ENVIRONMENT READY")

	-- Display connection info for manual testing
	local alloy_url = "http://localhost:" .. e2e_runner.state.alloy_port
	local backend_url = e2e_runner.state.backend_type == "loki" and loki_manager.get_loki_url()
		or mimir_manager.get_mimir_url()

	logger.success("✅ Alloy is running at: " .. alloy_url)
	logger.success("✅ Backend is running at: " .. backend_url)

	if e2e_runner.state.backend_type == "loki" then
		logger.info("To query Loki manually, use:")
		logger.code(
			'curl -G "'
				.. backend_url
				.. '/loki/api/v1/query_range" --data-urlencode "query={filename=\\"'
				.. log_file:gsub("\\", "/")
				.. '\\"}" --data-urlencode "start=1588889015000000000" --data-urlencode "end=1588889016000000000"'
		)
	else
		logger.info("To query Mimir manually, use:")
		logger.code(
			'curl -G -H "X-Scope-OrgID: fake" "'
				.. backend_url
				.. '/prometheus/api/v1/query" --data-urlencode "query={job=\\"pcp-metrics\\"}"'
		)
	end

	-- Detect WSL and provide appropriate backend URL
	local function is_wsl()
		local output = vim.fn.system("uname -r")
		return output:lower():match("microsoft") ~= nil or output:lower():match("wsl") ~= nil
	end

	local function get_wsl_ip()
		local ip = vim.fn.system("ip addr show eth0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'"):gsub("%s+", "")
		if ip == "" then
			-- Try another common interface name
			ip = vim.fn.system("ip addr show bond0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'"):gsub("%s+", "")
		end
		return ip
	end

	-- Adjust backend URL for WSL if needed for external access
	local adjusted_backend_url = backend_url
	if is_wsl() then
		local wsl_ip = get_wsl_ip()
		if wsl_ip ~= "" then
			-- For user's manual querying from Windows
			logger.info("WSL detected - for querying from Windows, replace 'localhost' with your WSL IP: " .. wsl_ip)

			if e2e_runner.state.backend_type == "loki" then
				logger.info("WSL Windows query example:")
				logger.code(
					'curl -G "http://'
						.. wsl_ip
						.. ':9000/loki/api/v1/query_range" --data-urlencode "query={filename=\\"'
						.. log_file:gsub("\\", "/")
						.. '\\"}" --data-urlencode "start=1588889015000000000" --data-urlencode "end=1588889016000000000"'
				)
			else
				logger.info("WSL Windows query example:")
				logger.code(
					'curl -G -H "X-Scope-OrgID: fake" "http://'
						.. wsl_ip
						.. ':9009/prometheus/api/v1/query" --data-urlencode "query={job=\\"pcp-metrics\\"}"'
				)
			end
		end
	end

	-- Start Grafana and connect it to the appropriate backend
	logger.info("Starting Grafana container...")

	-- For Mimir, add fallback options
	if e2e_runner.state.backend_type == "mimir" then
		logger.info("✅ Mimir Configuration Recommendations:")

		-- Provide known working Alloy configuration for cockpit-pcp to Mimir
		logger.info("📋 Here's a simple configuration for collecting cockpit-pcp metrics to Mimir:")
		logger.code([[
// Simplified Alloy configuration for cockpit-pcp to Mimir
prometheus.remote_write "mimir" {
    endpoint {
        url = "http://localhost:9009/api/v1/push"
    }
}

prometheus.scrape "pcp" {
    targets = [
        {"__address__" = "127.0.0.1:44322", "job" = "pcp-metrics"},
    ]
    metrics_path = "/metrics"
    forward_to = [prometheus.remote_write.mimir.receiver]
}

livedebugging {
    enabled = true
}
]])

		-- Provide file-based fallback
		logger.info("🔄 If you continue having issues with Mimir, try this file-based fallback:")
		logger.code([[
// Write metrics to files instead of Mimir
prometheus.scrape "pcp" {
    targets = [
        {"__address__" = "127.0.0.1:44322", "job" = "pcp-metrics"},
    ]
    metrics_path = "/metrics"
    scrape_interval = "15s"
    
    forward_to = [prometheus.write.file.receiver]
}

prometheus.write "file" {
    directory = "/tmp/metrics"
    format = "text"
}

livedebugging {
    enabled = true
}
]])
	end

	grafana_manager.start_grafana(e2e_runner.state.backend_type, backend_url, function(success)
		if success then
			local grafana_url = grafana_manager.get_grafana_url()
			logger.success("✅ Grafana is running at: " .. grafana_url)

			-- If WSL, show additional access information
			if is_wsl() then
				local wsl_ip = get_wsl_ip()
				if wsl_ip ~= "" then
					local wsl_grafana_url = "http://" .. wsl_ip .. ":" .. grafana_url:match(":(%d+)")
					logger.success("✅ For Windows access, use: " .. wsl_grafana_url)
					logger.info(
						"⚠️ Grafana needs to access your WSL backend at: " .. wsl_ip .. " instead of localhost"
					)
					logger.info("⚠️ If you see connection errors in Grafana, you may need to:")
					logger.info("   1. Connect to the WSL Grafana URL from Windows")
					logger.info("   2. Edit the datasource to use the WSL IP instead of localhost")
					logger.info("   3. If issues persist, check Windows Firewall settings for WSL connections")
				end
			end

			logger.info("Open your browser to access the Grafana dashboard")

			-- Auto-login is enabled, just go to Explore for quick access
			logger.info("Quick links:")
			logger.info("- Explore: " .. grafana_url .. "/explore")

			-- Create example query to help user get started
			if e2e_runner.state.backend_type == "loki" then
				logger.info('Example Loki query in Explore: {filename=~"' .. log_file:gsub("\\", "/") .. '"}')
			else
				logger.info('Example Prometheus query in Explore: {job="pcp-metrics"}')
			end

			-- Notify the user that Grafana is ready
			vim.notify("✅ Grafana dashboard is ready at: " .. grafana_url, vim.log.levels.INFO)
		else
			logger.error("Failed to start Grafana container. Proceeding without Grafana.")
		end
	end, logger)

	logger.info("When you are done testing, run the cleanup action or close Neovim.")

	-- Set a timer to wait 2 seconds after Alloy starts for better UX
	vim.loop.new_timer():start(
		2000,
		0,
		vim.schedule_wrap(function()
			-- Notify the user that the environment is ready
			vim.notify("✅ Alloy test environment is ready for manual testing!", vim.log.levels.INFO)
		end)
	)
end

function M.setup_test_env(opts)
	opts = opts or {}
	local source_bufnr = opts.source_bufnr or vim.api.nvim_get_current_buf()
	local logger = e2e_runner.create_logger()

	if not utils.validate_buffer(source_bufnr) then
		logger.error("Invalid buffer provided for test environment setup.")
		return false
	end

	utils.notify_debug("Test environment setup initiated for buffer: " .. source_bufnr)
	vim.notify("🚀 Setting up Alloy test environment...")

	if vim.bo[source_bufnr].filetype ~= "alloy" and not opts.pipeline_components then
		logger.error("Test runner must be initiated from an Alloy buffer or a diagram linked to one.")
		return false
	end

	-- Determine backend type
	e2e_runner.state.backend_type = "loki" -- Default
	if opts.pipeline_components and #opts.pipeline_components > 0 then
		local last_component = opts.pipeline_components[#opts.pipeline_components]
		if last_component.type == "prometheus.remote_write" then
			e2e_runner.state.backend_type = "mimir"
		end
	else
		-- Fallback for whole-file tests: parse the buffer and check the last component of the first pipeline
		local components, all_chains, _ = parser.get_parsed_pipeline_data(source_bufnr)
		if components and all_chains and #all_chains > 0 then
			local first_chain = all_chains[1]
			local last_comp_key = first_chain[#first_chain]
			if components[last_comp_key].type == "prometheus.remote_write" then
				e2e_runner.state.backend_type = "mimir"
			end
		end
	end
	logger.info("Detected backend type: " .. e2e_runner.state.backend_type)

	log_window.set_source_win_id(vim.api.nvim_get_current_win())
	e2e_runner.state.last_source_bufnr = source_bufnr
	e2e_runner.state.test_dir = vim.fn.tempname()
	e2e_runner.state.last_summary_data = nil
	if e2e_runner.state.summary_win_id and vim.api.nvim_win_is_valid(e2e_runner.state.summary_win_id) then
		vim.api.nvim_win_close(e2e_runner.state.summary_win_id, true)
		e2e_runner.state.summary_win_id = nil
	end

	log_window.setup_output_buffer()
	log_window.set_diff_ns_id(vim.api.nvim_create_namespace("alloy_test_diff"))
	vim.api.nvim_create_autocmd("VimLeave", { pattern = "*", callback = e2e_runner.cleanup, once = true })

	e2e_runner.state.alloy_data_dir = vim.fn.tempname()
	vim.fn.mkdir(e2e_runner.state.test_dir, "p")
	vim.fn.mkdir(e2e_runner.state.alloy_data_dir, "p")

	local service_manager = e2e_runner.state.backend_type == "loki" and loki_manager or mimir_manager
	local start_function = e2e_runner.state.backend_type == "loki" and service_manager.start_loki
		or service_manager.start_mimir

	-- Prepare backend only once, then start Alloy test environment
	start_function(function()
		start_alloy_env(logger, opts)
	end, logger, e2e_runner.state.test_dir)
end

return M

