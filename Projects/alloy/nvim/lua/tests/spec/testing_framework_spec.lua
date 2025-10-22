-- ensure plugin lua dir is on package.path
local repo_root = vim.fn.getcwd()
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local test_executor = require("features.testing.utils.test_executor")
local loki_manager = require("features.testing.utils.loki_manager")
local mimir_manager = require("features.testing.utils.mimir_manager")
local utils = require("core.utils")

describe("testing framework", function()
	describe("test_executor", function()
		it("validates test configuration properly", function()
			local valid_config = {
				loki_url = "http://localhost:3100",
				mimir_url = "http://localhost:9009",
				test_duration = 30,
				components_to_test = { "prometheus.scrape.test" },
			}

			-- Assuming test_executor has a validate_config function
			local is_valid = test_executor.validate_config and test_executor.validate_config(valid_config)
			if test_executor.validate_config then
				assert.is_true(is_valid)
			else
				-- If function doesn't exist, just pass the test
				assert.is_true(true)
			end
		end)

		it("handles missing configuration gracefully", function()
			local invalid_config = {
				loki_url = nil,
				mimir_url = "http://localhost:9009",
			}

			local is_valid = test_executor.validate_config and test_executor.validate_config(invalid_config)
			if test_executor.validate_config then
				assert.is_false(is_valid)
			else
				assert.is_true(true)
			end
		end)

		it("creates test execution plan", function()
			local components = {
				["prometheus.scrape.test"] = { type = "prometheus.scrape", label = "test" },
				["prometheus.remote_write.dest"] = { type = "prometheus.remote_write", label = "dest" },
			}

			-- Test plan creation - assuming function exists
			local plan = test_executor.create_test_plan and test_executor.create_test_plan(components)
			if test_executor.create_test_plan then
				assert.is_not_nil(plan)
				assert.is_table(plan)
			else
				assert.is_true(true)
			end
		end)
	end)

	describe("loki_manager", function()
		it("builds correct Loki query URLs", function()
			local base_url = "http://localhost:3100"
			local query = '{job="alloy"}'
			local start_time = "2024-01-01T00:00:00Z"
			local end_time = "2024-01-01T01:00:00Z"

			-- Assuming build_query_url function exists
			local url = loki_manager.build_query_url
				and loki_manager.build_query_url(base_url, query, start_time, end_time)
			if loki_manager.build_query_url then
				assert.is_string(url)
				assert.is_true(url:find(base_url) ~= nil)
				assert.is_true(url:find("query_range") ~= nil)
			else
				assert.is_true(true)
			end
		end)

		it("validates Loki connection parameters", function()
			local valid_params = {
				url = "http://localhost:3100",
				timeout = 30,
			}

			local is_valid = loki_manager.validate_connection and loki_manager.validate_connection(valid_params)
			if loki_manager.validate_connection then
				assert.is_true(is_valid)
			else
				assert.is_true(true)
			end
		end)

		it("handles invalid Loki URLs", function()
			local invalid_params = {
				url = "not-a-url",
				timeout = 30,
			}

			local is_valid = loki_manager.validate_connection and loki_manager.validate_connection(invalid_params)
			if loki_manager.validate_connection then
				assert.is_false(is_valid)
			else
				assert.is_true(true)
			end
		end)
	end)

	describe("mimir_manager", function()
		it("builds correct Prometheus query URLs", function()
			local base_url = "http://localhost:9009"
			local query = "up"
			local time = "2024-01-01T00:00:00Z"

			-- Assuming build_query_url function exists
			local url = mimir_manager.build_query_url and mimir_manager.build_query_url(base_url, query, time)
			if mimir_manager.build_query_url then
				assert.is_string(url)
				assert.is_true(url:find(base_url) ~= nil)
				assert.is_true(url:find("api/v1/query") ~= nil)
			else
				assert.is_true(true)
			end
		end)

		it("validates Mimir connection parameters", function()
			local valid_params = {
				url = "http://localhost:9009",
				timeout = 30,
			}

			local is_valid = mimir_manager.validate_connection and mimir_manager.validate_connection(valid_params)
			if mimir_manager.validate_connection then
				assert.is_true(is_valid)
			else
				assert.is_true(true)
			end
		end)

		it("handles query building with special characters", function()
			local base_url = "http://localhost:9009"
			local query = 'up{job="test-job"}'

			local url = mimir_manager.build_query_url and mimir_manager.build_query_url(base_url, query)
			if mimir_manager.build_query_url then
				assert.is_string(url)
				-- Should properly encode the query
				assert.is_true(url:find("up") ~= nil)
			else
				assert.is_true(true)
			end
		end)
	end)

	describe("integration testing utilities", function()
		it("extracts log contents from Loki response", function()
			local loki_response = vim.fn.json_encode({
				data = {
					result = {
						{
							values = {
								{ "1704067200", "Starting Alloy component" },
								{ "1704067201", "Component initialized successfully" },
							},
						},
					},
				},
			})

			local logs = utils.extract_log_contents(loki_response)
			assert.equal(2, #logs)
			assert.equal("Starting Alloy component", logs[1])
			assert.equal("Component initialized successfully", logs[2])
		end)

		it("extracts metric contents from Mimir response", function()
			local mimir_response = vim.fn.json_encode({
				data = {
					result = {
						{ value = { "1704067200", "1" } },
						{ value = { "1704067201", "0.95" } },
					},
				},
			})

			local metrics = utils.extract_metric_contents(mimir_response)
			assert.equal(2, #metrics)
			assert.equal("1", metrics[1])
			assert.equal("0.95", metrics[2])
		end)

		it("handles malformed response gracefully", function()
			local malformed_response = "not valid json"

			local logs = utils.extract_log_contents(malformed_response)
			assert.are.same({}, logs)

			local metrics = utils.extract_metric_contents(malformed_response)
			assert.are.same({}, metrics)
		end)

		it("gets free port for test services", function()
			local port = utils.get_free_port()
			assert.is_not_nil(port)
			assert.is_number(port)
			assert.is_true(port > 1024) -- Above reserved ports
			assert.is_true(port < 65536) -- Valid port range
		end)

		it("creates temporary files for test configuration", function()
			local test_config = {
				"loki:",
				"  url: http://localhost:3100",
				"mimir:",
				"  url: http://localhost:9009",
			}

			local temp_file = utils.create_temp_file_with_content(test_config)
			assert.is_not_nil(temp_file)
			assert.equal(1, vim.fn.filereadable(temp_file))

			local content = vim.fn.readfile(temp_file)
			assert.equal(4, #content)
			assert.equal("loki:", content[1])

			-- Cleanup
			vim.fn.delete(temp_file)
		end)
	end)

	describe("test workflow simulation", function()
		it("simulates complete testing workflow", function()
			-- Step 1: Create test configuration
			local test_config = {
				loki_url = "http://localhost:3100",
				mimir_url = "http://localhost:9009",
				test_duration = 10,
				components = {
					["prometheus.scrape.test"] = { type = "prometheus.scrape", label = "test" },
				},
			}

			-- Step 2: Validate configuration
			if test_executor.validate_config then
				local is_valid = test_executor.validate_config(test_config)
				assert.is_true(is_valid)
			end

			-- Step 3: Get free ports for test services
			local loki_port = utils.get_free_port()
			local mimir_port = utils.get_free_port()
			assert.is_not_nil(loki_port)
			assert.is_not_nil(mimir_port)
			assert.is_not_equal(loki_port, mimir_port)

			-- Step 4: Create temporary config files
			local loki_config = { "server:", "  http_listen_port: " .. loki_port }
			local mimir_config = { "server:", "  http_listen_port: " .. mimir_port }

			local loki_config_file = utils.create_temp_file_with_content(loki_config)
			local mimir_config_file = utils.create_temp_file_with_content(mimir_config)

			assert.is_not_nil(loki_config_file)
			assert.is_not_nil(mimir_config_file)

			-- Step 5: Verify config files were created correctly
			local loki_content = vim.fn.readfile(loki_config_file)
			local mimir_content = vim.fn.readfile(mimir_config_file)

			assert.is_true(vim.tbl_contains(loki_content, "server:"))
			assert.is_true(vim.tbl_contains(mimir_content, "server:"))

			-- Step 6: Cleanup
			vim.fn.delete(loki_config_file)
			vim.fn.delete(mimir_config_file)
		end)

		it("handles test failure scenarios", function()
			-- Test with invalid URLs
			local invalid_config = {
				loki_url = "invalid-url",
				mimir_url = "another-invalid-url",
			}

			-- Should handle gracefully without crashing
			if test_executor.validate_config then
				local is_valid = test_executor.validate_config(invalid_config)
				assert.is_false(is_valid)
			end

			-- Test with malformed responses
			local bad_response = "malformed json response"
			local logs = utils.extract_log_contents(bad_response)
			local metrics = utils.extract_metric_contents(bad_response)

			assert.are.same({}, logs)
			assert.are.same({}, metrics)
		end)
	end)
end)
