--- Core utilities for the Alloy plugin.
---
--- This module provides common utility functions used throughout the plugin,
--- including validation helpers, cursor management, popup creation, and
--- performance utilities like memoization.
---
--- @version 2.0.0
--- @module core.util

local configuration = require("main._core.configuration")

local M = {}

function M.safe_call(fn, default)
	local ok, result = pcall(fn)
	if ok then
		return result
	end
	return default
end

function M.validate_buffer(bufnr)
	return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

function M.validate_window(win_id)
	return win_id and vim.api.nvim_win_is_valid(win_id)
end

function M.notify_debug_chunks(chunks)
	local cfg = configuration.resolve_data()
	if not cfg.debug then
		return
	end
	table.insert(chunks, 1, { "Alloy Tools ", "@punctuation" }) -- "Title" is just an example highlight
	vim.api.nvim_echo(chunks, false, {})
end

function M.notify_debug(msg, level)
	local cfg = configuration.resolve_data()

	if not cfg.debug then
		return
	end
	local final_msg = "[Alloy Tools] " .. tostring(msg)
	vim.notify(final_msg, level or vim.log.levels.INFO)
end

function M.get_cursor_component(bufnr, components)
	if not (M.validate_buffer(bufnr) and components) then
		return nil
	end

	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

	for key, comp_data in pairs(components) do
		if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
			return key, comp_data
		end
	end

	return nil, nil
end

function M.get_cursor_component_key(bufnr, components)
	local key, _ = M.get_cursor_component(bufnr, components)
	return key
end

function M.get_free_port()
	local server = vim.loop.new_tcp()
	if not server then
		return nil
	end
	if server:bind("0.0.0.0", 0) ~= 0 then
		server:close()
		return nil
	end
	local sock_info = server:getsockname()
	server:close()
	return sock_info and sock_info.port
end

function M.center_text(text, width)
	local text_width = vim.fn.strwidth(text)
	if text_width >= width then
		return text
	end
	local padding_total = width - text_width
	local padding_left = math.floor(padding_total / 2)
	local padding_right = math.ceil(padding_total / 2)
	return string.rep(" ", padding_left) .. text .. string.rep(" ", padding_right)
end

function M.read_file_from_tests_dir(filename, override_dir_name)
	local file_path = vim.fn.getcwd() .. "/" .. override_dir_name .. "/" .. filename
	if vim.fn.filereadable(file_path) == 0 then
		return nil, string.format("Required test file not found or not readable: %s", file_path)
	end
	local lines = vim.fn.readfile(file_path)
	local clean_lines = {}
	for _, line in ipairs(lines) do
		if line ~= "" then
			table.insert(clean_lines, line)
		end
	end
	return clean_lines, nil
end

function M.create_temp_file_with_content(content)
	local temp_file = vim.fn.tempname()
	local lines = type(content) == "string" and vim.split(content, "\n") or content
	vim.fn.writefile(lines, temp_file)
	return temp_file
end

function M.extract_log_contents(loki_result)
	local ok, parsed = pcall(vim.fn.json_decode, loki_result)
	if not ok or not parsed.data or not parsed.data.result then
		return {}
	end
	local found_logs = {}
	for _, result_entry in ipairs(parsed.data.result) do
		if result_entry.values then
			for _, value_pair in ipairs(result_entry.values) do
				table.insert(found_logs, value_pair[2])
			end
		end
	end
	return found_logs
end

function M.notify_with_context(msg, level, context)
	local full_msg = context and string.format("[%s] %s", context, msg) or msg
	vim.notify(full_msg, level or vim.log.levels.INFO)
end

function M.create_namespace(name)
	return vim.api.nvim_create_namespace(name)
end

function M.clear_namespace(bufnr, ns_id)
	if M.validate_buffer(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	end
end

function M.debounce(fn, delay)
	local timer = nil
	return function(...)
		local args = { ... }
		if timer then
			timer:close()
		end
		timer = vim.loop.new_timer()
		timer:start(delay, 0, function()
			vim.schedule(function()
				fn(unpack(args))
			end)
		end)
	end
end

function M.jump_to_line(win_id, line, col)
	if not M.validate_window(win_id) then
		return false
	end

	vim.api.nvim_win_set_cursor(win_id, { line, col or 0 })
	vim.fn.win_execute(win_id, "normal! zz")
	return true
end

function M.extract_metric_contents(json_string)
	local ok, data = pcall(vim.fn.json_decode, json_string)
	if not ok or not data or not data.data or not data.data.result then
		return {}
	end

	local contents = {}
	for _, result in ipairs(data.data.result) do
		if result.metric then
			-- Create label set representation like {job="pcp-metrics",instance="127.0.0.1:44322"}
			local label_parts = {}
			for k, v in pairs(result.metric) do
				if k ~= "__name__" then
					table.insert(label_parts, k .. '="' .. v .. '"')
				end
			end
			table.sort(label_parts) -- Sort for consistent output
			local label_str = "{" .. table.concat(label_parts, ",") .. "}"
			table.insert(contents, label_str)

			-- If there's a value, also add the metric with value for debugging
			if result.value and type(result.value) == "table" and result.value[2] then
				local metric_name = result.metric.__name__ or ""
				if metric_name ~= "" then
					table.insert(contents, metric_name .. label_str .. " " .. result.value[2])
				end
			end
		end
	end
	return contents
end

function M.create_simple_popup(content, title, opts)
	local popup = require("ui.popup")
	opts = opts or {}
	opts.title = title
	return popup.create_popup(content, opts)
end

function M.memoize(fn)
	local cache = {}
	return function(...)
		local key = table.concat({ ... }, "|")
		if cache[key] == nil then
			cache[key] = fn(...)
		end
		return cache[key]
	end
end

function M.with_fallback(value, fallback)
	return value ~= nil and value or fallback
end

function M.open_url_in_browser(url, service_name)
	if url then
		vim.fn.system('/mnt/c/Program\\ Files/Google/Chrome/Application/chrome.exe "' .. url .. '"')
		vim.notify("Opening " .. service_name .. ": " .. url, vim.log.levels.INFO)
	else
		vim.notify(service_name .. " is not running", vim.log.levels.WARN)
	end
end

return M
