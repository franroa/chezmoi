local utils = require("core.utils")
local parser = require("core.parser")
local loki_manager = require("features.testing.utils.loki_manager")
local mimir_manager = require("features.testing.utils.mimir_manager")
local log_window = require("ui.log_window")
local test_executor = require("features.testing.utils.test_executor")
local block_overrides = require("features.testing.utils.block_overrides")
local integration_state = require("core.alloy_integration_state")
local test_summary = require("ui.test_summary")

local e2e_runner = require("features.testing.utils.e2e_runner")
local M = {}

local function start_alloy_and_test(logger, opts)
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

	-- For logging purposes, show the URLs being used
	logger.info("Using Loki URL: " .. placeholders.LOKI_URL)
	logger.info("Using Mimir URL: " .. placeholders.MIMIR_URL)

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

	logger.step("3. VERIFYING ALLOY IS READY")
	-- Backend already started by M.run; directly query and verify now that Alloy is running.
	test_executor.execute_query_and_verify(
		e2e_runner.state.test_dir,
		e2e_runner.state.backend_type == "loki" and loki_manager.get_loki_url() or mimir_manager.get_mimir_url(),
		e2e_runner.config.override_dir_name,
		logger,
		e2e_runner.state.backend_type,
		function(summary_data)
			e2e_runner.state.last_summary_data = summary_data
			integration_state.last_summary_data = summary_data
			integration_state.notify_debug("Test finished. Passed: " .. tostring(summary_data.test_passed))
			if
				integration_state.visualizer_module and integration_state.visualizer_module.update_diagram_with_results
			then
				integration_state.visualizer_module.update_diagram_with_results(summary_data)
			end
			e2e_runner.state.summary_win_id = test_summary.show_summary(summary_data)
			e2e_runner.cleanup()
		end
	)
end
function M.run(opts)
	opts = opts or {}
	local source_bufnr = opts.source_bufnr or vim.api.nvim_get_current_buf()
	local logger = e2e_runner.create_logger()

	if not utils.validate_buffer(source_bufnr) then
		logger.error("Invalid buffer provided for test run.")
		return false
	end

	utils.notify_debug("Test run initiated for buffer: " .. source_bufnr)
	vim.notify("🚀 Starting Alloy E2E test...")

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

	-- Prepare backend only once, then start Alloy and run tests
	start_function(function()
		start_alloy_and_test(logger, opts)
	end, logger, e2e_runner.state.test_dir)
end

return M
