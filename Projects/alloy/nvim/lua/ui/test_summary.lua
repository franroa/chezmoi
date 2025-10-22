local M = {}

local popup = require("ui.popup")

local function generate_diff(expected_logs, found_logs)
	local expected_file = vim.fn.tempname()
	local found_file = vim.fn.tempname()
	vim.fn.writefile(expected_logs, expected_file)
	vim.fn.writefile(found_logs, found_file)
	local diff_result = vim.fn.system({ "diff", "-u", expected_file, found_file })
	vim.fn.delete(expected_file)
	vim.fn.delete(found_file)
	return vim.split(diff_result, "\n")
end

local function create_line_formatter(window_width)
	local divider = "╠" .. string.rep("═", window_width - 2) .. "╣"
	return function(text, align)
		align = align or "left"
		local padding = window_width - 4
		local content_text = text or ""
		local text_width = vim.fn.strwidth(content_text)
		if align == "center" then
			local left_pad = math.floor((padding - text_width) / 2)
			local right_pad = padding - text_width - left_pad
			return "║ " .. string.rep(" ", left_pad) .. content_text .. string.rep(" ", right_pad) .. " ║"
		else
			local right_pad = padding - text_width
			return "║ " .. content_text .. string.rep(" ", math.max(0, right_pad)) .. " ║"
		end
	end,
		divider
end

local function build_header(create_line, add_highlight, summary_data)
	local content = {}
	local status_icon, status_text, status_hl
	if summary_data.test_passed then
		status_icon, status_text, status_hl = "✅", "TEST PASSED", "DiagnosticOk"
	else
		status_icon, status_text, status_hl = "❌", "TEST FAILED", "DiagnosticError"
	end

	table.insert(content, create_line(string.format("%s %s", status_icon, status_text), "center"))
	add_highlight({ line = #content, hl_group = status_hl })

	local time_str = os.date("📅 %Y-%m-%d  ⏰ %H:%M:%S", summary_data.start_time)
	local duration_str = string.format("⏱️ %.2fs", summary_data.duration)
	table.insert(content, create_line(time_str .. " | " .. duration_str, "center"))
	add_highlight({ line = #content, hl_group = "Comment" })
	return content
end

local function build_stats(create_line, add_highlight, summary_data)
	local content = {}
	table.insert(content, create_line("📊 Test Statistics", "center"))
	add_highlight({ line = #content, hl_group = "Title" })
	table.insert(content, create_line()) -- Spacer
	table.insert(content, create_line(string.format("📖 Logs Expected: %d", #summary_data.logs_expected)))
	add_highlight({ line = #content, hl_group = "Number" })
	table.insert(content, create_line(string.format("🔍 Logs Found:    %d", #summary_data.logs_found)))
	add_highlight({ line = #content, hl_group = "Number" })
	table.insert(content, create_line(string.format("❌ Missing:       %d", #summary_data.missing_logs)))
	add_highlight({ line = #content, hl_group = "DiagnosticError" })
	table.insert(content, create_line(string.format("❗ Unexpected:    %d", #summary_data.unexpected_logs)))
	add_highlight({ line = #content, hl_group = "WarningMsg" })
	return content
end

local function build_diff_analysis(create_line, add_highlight, summary_data)
	local content = {}
	table.insert(content, create_line("🔎 Difference Analysis", "center"))
	add_highlight({ line = #content, hl_group = "Title" })
	table.insert(content, create_line()) -- Spacer

	if summary_data.test_passed then
		table.insert(content, create_line("  All expected logs were found.", "left"))
		add_highlight({ line = #content, hl_group = "DiagnosticOk" })
	else
		if #summary_data.missing_logs > 0 then
			table.insert(content, create_line("  ❌ Missing Logs (Expected but not found):", "left"))
			add_highlight({ line = #content, hl_group = "DiagnosticError" })
			for _, log in ipairs(summary_data.missing_logs) do
				table.insert(content, create_line("    - " .. log))
			end
		end
		if #summary_data.unexpected_logs > 0 then
			table.insert(content, create_line("  ❗ Unexpected Logs (Found but not expected):", "left"))
			add_highlight({ line = #content, hl_group = "WarningMsg" })
			for _, log in ipairs(summary_data.unexpected_logs) do
				table.insert(content, create_line("    + " .. log))
			end
		end
	end
	return content
end

local function build_footer(create_line, add_highlight)
	local content = {}
	local keymaps_text = "[q]uit | [d]iff | [i]nput logs | [e]xpected logs"
	table.insert(content, create_line(keymaps_text, "center"))
	add_highlight({ line = #content, hl_group = "Comment" })
	return content
end

local function show_summary_float(summary_data)
	local max_log_width = 80
	local all_logs = vim.list_extend(
		vim.list_extend(
			vim.list_extend(vim.list_extend({}, summary_data.logs_written), summary_data.logs_expected),
			summary_data.missing_logs
		),
		summary_data.unexpected_logs
	)
	for _, log in ipairs(all_logs) do
		max_log_width = math.max(max_log_width, vim.fn.strwidth(log) + 15)
	end
	local editor_width = vim.api.nvim_get_option("columns")
	local window_width = math.min(max_log_width, math.floor(editor_width * 0.95))

	local create_line, divider = create_line_formatter(window_width)
	local highlights = {}
	local add_highlight = function(hl)
		table.insert(highlights, hl)
	end

	local header_border = "╔" .. string.rep("═", window_width - 2) .. "╗"
	local footer_border = "╚" .. string.rep("═", window_width - 2) .. "╝"

	local content = { header_border }
	local current_line = 1

	local function extend_content(section_builder)
		local section_content = section_builder(create_line, function(hl)
			hl.line = hl.line + current_line
			add_highlight(hl)
		end, summary_data)
		vim.list_extend(content, section_content)
		current_line = #content
	end

	extend_content(build_header)
	table.insert(content, divider)
	current_line = current_line + 1
	extend_content(build_stats)
	table.insert(content, divider)
	current_line = current_line + 1
	extend_content(build_diff_analysis)
	table.insert(content, divider)
	current_line = current_line + 1
	extend_content(build_footer)
	table.insert(content, footer_border)

	local height = #content
	local editor_height = vim.api.nvim_get_option("lines")
	local row, col = math.floor((editor_height - height) / 2), math.floor((editor_width - window_width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	local win_opts = {
		relative = "editor",
		style = "minimal",
		width = window_width,
		height = height,
		row = row,
		col = col,
		border = "none",
		zindex = 50,
	}
	local win = vim.api.nvim_open_win(buf, true, win_opts)
	vim.api.nvim_win_set_buf(win, buf)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(buf, -1, hl.hl_group, hl.line - 1, 0, -1)
	end

	for i = 0, #content - 1 do
		vim.api.nvim_buf_add_highlight(buf, -1, "PopupBorder", i, 0, -1)
	end

	vim.bo[buf].buftype, vim.bo[buf].swapfile, vim.bo[buf].bufhidden, vim.bo[buf].filetype =
		"nofile", false, "wipe", "alloy-summary"

	local diff_win_id = nil
	local function toggle_diff_view()
		if diff_win_id and vim.api.nvim_win_is_valid(diff_win_id) then
			vim.api.nvim_win_close(diff_win_id, true)
			diff_win_id = nil
			return
		end

		if summary_data.test_passed then
			vim.notify("No diff to show for a successful test.", vim.log.levels.INFO)
			return
		end

		local diff_content = generate_diff(summary_data.logs_expected, summary_data.logs_found)
		if #diff_content == 0 then
			vim.notify("No differences found between expected and actual logs.", vim.log.levels.INFO)
			return
		end

		local diff_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[diff_buf].filetype = "diff"
		vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, diff_content)

		local diff_height = math.min(#diff_content + 2, 20)
		local diff_win = vim.api.nvim_open_win(diff_buf, true, {
			relative = "win",
			win = win,
			width = window_width,
			height = diff_height,
			row = height,
			col = 0,
			style = "minimal",
			border = "rounded",
			title = "Log Diff",
			title_pos = "center",
		})
		diff_win_id = diff_win

		for i, line in ipairs(diff_content) do
			if line:sub(1, 1) == "+" and not line:match("^%+%+%+") then
				vim.api.nvim_buf_add_highlight(diff_buf, -1, "AlloyDiffAdd", i - 1, 0, -1)
			elseif line:sub(1, 1) == "-" and not line:match("^%-%-%-") then
				vim.api.nvim_buf_add_highlight(diff_buf, -1, "AlloyDiffDelete", i - 1, 0, -1)
			end
		end
		local keymaps = require("main.keymaps")
		keymaps.register({
			{
				id = "diff-close-q",
				mode = "n",
				lhs = "q",
				rhs = function()
					if diff_win_id and vim.api.nvim_win_is_valid(diff_win_id) then
						vim.api.nvim_win_close(diff_win_id, true)
						diff_win_id = nil
					end
				end,
				opts = { buffer = diff_buf, nowait = true },
			},
		})
	end

	local close_win = function()
		if diff_win_id and vim.api.nvim_win_is_valid(diff_win_id) then
			vim.api.nvim_win_close(diff_win_id, true)
		end
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	local keymaps = require("main.keymaps")
	keymaps.register({
		{ id = "summary-close-q", mode = "n", lhs = "q", rhs = close_win, opts = { buffer = buf, nowait = true } },
		{
			id = "summary-close-esc",
			mode = "n",
			lhs = "<Esc>",
			rhs = close_win,
			opts = { buffer = buf, nowait = true },
		},
		{
			id = "summary-open-logs",
			mode = "n",
			lhs = "i",
			rhs = function()
				vim.cmd("vsplit " .. summary_data.logs_to_write_path)
			end,
			opts = { buffer = buf, nowait = true },
		},
		{
			id = "summary-open-expected",
			mode = "n",
			lhs = "e",
			rhs = function()
				vim.cmd("vsplit " .. summary_data.expected_logs_path)
			end,
			opts = { buffer = buf, nowait = true },
		},
		{
			id = "summary-toggle-diff",
			mode = "n",
			lhs = "d",
			rhs = toggle_diff_view,
			opts = { buffer = buf, nowait = true, desc = "Toggle Diff View" },
		},
	})

	return win
end

function M.show_summary(summary_data)
	return show_summary_float(summary_data)
end

return M
