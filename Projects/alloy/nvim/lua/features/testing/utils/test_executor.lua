local M = {}

local utils = require("core.utils")

local function read_file_from_tests_dir(filename, override_dir_name, logger)
	local lines, error_msg = utils.read_file_from_tests_dir(filename, override_dir_name)
	if not lines then
		logger.error(error_msg)
		return nil
	end
	return lines
end

function M.get_free_port()
	return utils.get_free_port()
end

function M.execute_query_and_verify(test_dir, query_url_base, override_dir_name, logger, backend_type, on_complete)
	logger.step("4. READING TEST CASE FILES")
	local input_file = backend_type == "loki" and "logs_input.log" or "metrics_input.txt"
	local expected_file = backend_type == "loki" and "logs_expected.log" or "metrics_expected.txt"

	local logs_to_write_path = vim.fn.getcwd() .. "/" .. override_dir_name .. "/" .. input_file
	local expected_logs_path = vim.fn.getcwd() .. "/" .. override_dir_name .. "/" .. expected_file

	local logs_to_write = {}
	local expected_logs = read_file_from_tests_dir(expected_file, override_dir_name, logger)
	if not expected_logs then
		return false
	end

	local test_start_time = vim.fn.localtime()
	local log_file = test_dir .. "/app.log"

	-- For Loki, we require input file, for Mimir it's optional
	if backend_type == "loki" then
		logs_to_write = read_file_from_tests_dir(input_file, override_dir_name, logger)
		if not logs_to_write then
			return false
		end
		if #logs_to_write == 0 then
			logger.error("`" .. input_file .. "` file is empty. Nothing to test.")
			return false
		end

		logger.step("5. WRITING TEST DATA")
		vim.fn.writefile(logs_to_write, log_file, "a")
		logger.info(string.format("%d lines written to %s:", #logs_to_write, log_file))
		logger.code(table.concat(logs_to_write, "\n"))
	else
		-- For Mimir, input file is optional
		logs_to_write = read_file_from_tests_dir(input_file, override_dir_name, logger) or {}
		if #logs_to_write > 0 then
			logger.step("5. WRITING TEST DATA")
			vim.fn.writefile(logs_to_write, log_file, "a")
			logger.info(string.format("%d lines written to %s:", #logs_to_write, log_file))
			logger.code(table.concat(logs_to_write, "\n"))
		else
			logger.info("No input file required for Mimir test. Using server-provided metrics.")
		end
	end

	logger.info("Waiting 3 seconds for Alloy to process...")

	vim.loop.new_timer():start(
		3000,
		0,
		vim.schedule_wrap(function()
			local query_url, query, curl_cmd
			local query_step_title = backend_type == "loki" and "6. QUERYING LOKI" or "6. QUERYING MIMIR"
			logger.step(query_step_title)

			if backend_type == "loki" then
				query_url = string.format("%s/loki/api/v1/query_range", query_url_base)
				query = string.format('{filename="%s"}', log_file:gsub("\\", "/"))
				local start_ns = string.format("%.0f", (test_start_time - 1) * 1e9)
				local end_ns = string.format("%.0f", (vim.fn.localtime() + 1) * 1e9)
				curl_cmd = {
					"curl",
					"-G",
					"-s",
					query_url,
					"--data-urlencode",
					"query=" .. query,
					"--data-urlencode",
					"start=" .. start_ns,
					"--data-urlencode",
					"end=" .. end_ns,
				}
			else -- mimir
				-- With Mimir's API prefix configuration, the correct path is /prometheus/api/v1/query
				query_url = string.format("%s/prometheus/api/v1/query", query_url_base)
				-- For Mimir, query for any metrics from pcp job
				query = '{job="pcp-metrics"}'
				logger.info("Querying Mimir at: " .. query_url)
				-- With auth_enabled: false, no headers needed
				curl_cmd = {
					"curl",
					"-G",
					"-s",
					"-v",
					query_url,
					"--data-urlencode",
					"query=" .. query,
				}
			end

			logger.info("Running query:")
			logger.code(table.concat(curl_cmd, " "))
			vim.fn.jobstart(curl_cmd, {
				stdout_buffered = true,
				on_stdout = vim.schedule_wrap(function(_, data)
					if not data then
						logger.error("No data received from query.")
						return
					end

					logger.step("7. ANALYZING RESULTS")
					local test_end_time = vim.fn.localtime()
					local result_json = table.concat(data, "\n")
					local found_logs
					if backend_type == "loki" then
						found_logs = utils.extract_log_contents(result_json)
					else
						found_logs = utils.extract_metric_contents(result_json)
					end

					local found_set = {}
					for _, log in ipairs(found_logs) do
						found_set[log] = true
					end
					local expected_set = {}
					for _, log in ipairs(expected_logs) do
						expected_set[log] = true
					end
					local missing_logs = {}
					for _, log in ipairs(expected_logs) do
						if not found_set[log] then
							table.insert(missing_logs, log)
						end
					end
					local unexpected_logs = {}
					for _, log in ipairs(found_logs) do
						if not expected_set[log] then
							table.insert(unexpected_logs, log)
						end
					end
					local test_passed
					if backend_type == "loki" then
						test_passed = (#missing_logs == 0 and #unexpected_logs == 0)
					else
						-- For Mimir, we just check if we got any metrics matching our expected labels
						-- We don't care about exact matches since metrics values will change
						test_passed = #found_logs > 0

						-- Check if any found log contains pattern from expected logs
						if #found_logs > 0 then
							local has_matching_label = false
							for _, found in ipairs(found_logs) do
								for _, expected in ipairs(expected_logs) do
									-- Extract the metric name from expected to use as pattern
									local label_pattern = expected:match("{(.-)}")
									if label_pattern and found:find(label_pattern, 1, true) then
										has_matching_label = true
										break
									end
								end
								if has_matching_label then
									break
								end
							end
							test_passed = has_matching_label
						end
					end

					local summary_data = {
						logs_written = logs_to_write,
						logs_expected = expected_logs,
						logs_found = found_logs,
						missing_logs = missing_logs,
						unexpected_logs = unexpected_logs,
						test_passed = test_passed,
						start_time = test_start_time,
						duration = test_end_time - test_start_time,
						logs_to_write_path = logs_to_write_path,
						expected_logs_path = expected_logs_path,
						backend_type = backend_type,
					}

					if test_passed then
						logger.success("✅ TEST PASSED")
						vim.notify("✅ Alloy E2E Test Passed!")
					else
						logger.error("❌ TEST FAILED")
						vim.notify("❌ Alloy E2E Test Failed!", vim.log.levels.ERROR)
					end

					on_complete(summary_data)
				end),
			})
		end)
	)

	return true
end

return M
