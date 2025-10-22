local help_window = require("ui.help_window")

local M = {}

local state = {
	output_buf = nil,
	output_win = nil,
	diff_ns_id = nil,
	source_win_id = nil,
}

local function find_log_window()
	for _, win_id in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win_id) then
			local buf_id = vim.api.nvim_win_get_buf(win_id)
			local ok, is_log_buffer = pcall(vim.api.nvim_buf_get_var, buf_id, "is_alloy_test_log_buffer")
			if ok and is_log_buffer then
				return win_id, buf_id
			end
		end
	end
	return nil, nil
end

local function open_log_window(buf_id)
	local win_id, _ = find_log_window()
	if win_id and vim.api.nvim_win_is_valid(win_id) then
		vim.api.nvim_win_close(win_id, true)
	end

	vim.cmd("15vsplit")
	local new_win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(new_win_id, buf_id)
	state.output_win = new_win_id
	return new_win_id
end

local function jump_to_source_window()
	if state.source_win_id and vim.api.nvim_win_is_valid(state.source_win_id) then
		vim.api.nvim_set_current_win(state.source_win_id)
	else
		vim.notify("Source window not found or was closed.", vim.log.levels.WARN)
	end
end

function M.toggle_test_log_window()
	local win_id, _ = find_log_window()
	if win_id and vim.api.nvim_win_is_valid(win_id) then
		vim.api.nvim_win_close(win_id, true)
	else
		if state.output_buf and vim.api.nvim_buf_is_valid(state.output_buf) then
			open_log_window(state.output_buf)
		else
			vim.notify("No active test log to show.", vim.log.levels.WARN)
		end
	end
end

function M.setup_output_buffer()
	if not (state.output_buf and vim.api.nvim_buf_is_valid(state.output_buf)) then
		local buf_id = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_var(buf_id, "is_alloy_test_log_buffer", true)
		vim.api.nvim_buf_set_name(buf_id, "alloy_tests")
		vim.bo[buf_id].buftype = "nofile"
		vim.bo[buf_id].swapfile = false
		vim.bo[buf_id].bufhidden = "hide"
		vim.bo[buf_id].filetype = "markdown"
		state.output_buf = buf_id
	end

	open_log_window(state.output_buf)

	vim.api.nvim_buf_set_lines(state.output_buf, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(state.output_buf, 0, 0, false, { "--- Alloy & Loki Test Results (g? for help) ---" })
	local keymaps = require("main.keymaps")
	keymaps.register({
		{
			id = "log-help",
			mode = "n",
			lhs = "g?",
			rhs = help_window.show_help,
			opts = { buffer = state.output_buf, nowait = true },
		},
		{
			id = "log-close",
			mode = "n",
			lhs = "q",
			rhs = M.toggle_test_log_window,
			opts = { buffer = state.output_buf, nowait = true, silent = true, desc = "Hide Test Log" },
		},
		{
			id = "log-jump-src",
			mode = "n",
			lhs = "<C-k>",
			rhs = jump_to_source_window,
			opts = { buffer = state.output_buf, nowait = true, silent = true, desc = "Jump to Source Window" },
		},
	})

	return state.output_buf
end

function M.log_message(msg_or_lines, hl_group)
	if not state.output_buf or not vim.api.nvim_buf_is_valid(state.output_buf) then
		return
	end
	local lines = type(msg_or_lines) == "table" and msg_or_lines or vim.split(tostring(msg_or_lines), "\n")
	local start_line = vim.api.nvim_buf_line_count(state.output_buf)
	vim.api.nvim_buf_set_lines(state.output_buf, -1, -1, false, lines)
	if hl_group then
		for i = 0, #lines - 1 do
			vim.api.nvim_buf_add_highlight(state.output_buf, -1, hl_group, start_line + i, 0, -1)
		end
	end
	local win_id = vim.fn.bufwinid(state.output_buf)
	if win_id ~= -1 then
		vim.api.nvim_win_set_cursor(win_id, { vim.api.nvim_buf_line_count(state.output_buf), 0 })
	end
end

function M.print_code_in_box(title, lines_data)
	if not (state.output_buf and vim.api.nvim_buf_is_valid(state.output_buf)) then
		return
	end

	-- ensure we have a namespace for our extmarks/highlights
	if not state.diff_ns_id then
		state.diff_ns_id = vim.api.nvim_create_namespace("alloy_test_diff_ns")
	end

	local diff_add_bg_color = "#1E2B1E"
	local diff_del_bg_color = "#2B1E1E"

	-- define highlight groups
	vim.api.nvim_set_hl(0, "AlloyTestDiffAddBg", { bg = diff_add_bg_color })
	vim.api.nvim_set_hl(0, "AlloyTestDiffDelBg", { fg = "#808080", bg = diff_del_bg_color })
	vim.api.nvim_set_hl(0, "AlloyTestVirtAdd", { fg = "#6A9A6A", bg = diff_add_bg_color, bold = true })
	vim.api.nvim_set_hl(0, "AlloyTestVirtDel", { fg = "#A06060", bg = diff_del_bg_color, bold = true })

	-- header line
	M.log_message("[INFO] " .. title, "Comment")

	-- avoid nuking other namespaces: clear only our namespace
	vim.api.nvim_buf_clear_namespace(state.output_buf, state.diff_ns_id, 0, -1)

	-- build the displayed lines
	local display_lines = { "", "```river", "" }
	for _, line_data in ipairs(lines_data) do
		table.insert(display_lines, line_data.content)
	end
	table.insert(display_lines, "")
	table.insert(display_lines, "```")
	table.insert(display_lines, "")

	local start_line = vim.api.nvim_buf_line_count(state.output_buf)
	M.log_message(display_lines)

	-- set extmarks (one extmark per line) with high priority and both line/text highlight options
	for i, line_data in ipairs(lines_data) do
		local line_to_highlight = start_line + 3 + (i - 1)
		local hl_group, virt_text_data
		if line_data.type == "added" then
			hl_group = "AlloyTestDiffAddBg"
			virt_text_data = { { "+", "AlloyTestVirtAdd" } }
		elseif line_data.type == "removed" then
			hl_group = "AlloyTestDiffDelBg"
			virt_text_data = { { "-", "AlloyTestVirtDel" } }
		end

		if hl_group and virt_text_data then
			vim.api.nvim_buf_set_extmark(state.output_buf, state.diff_ns_id, line_to_highlight, 0, {
				-- both text-region and whole-line styling
				hl_group = hl_group,
				line_hl_group = hl_group,
				hl_eol = true,
				-- paint until the next row (safer for some renderers)
				end_row = line_to_highlight + 1,
				virt_text = virt_text_data,
				virt_text_pos = "overlay",
				-- give it a very high priority so it wins over renderer extmarks
				priority = 10000,
			})
		end
	end
end

function M.set_source_win_id(win_id)
	state.source_win_id = win_id
end

function M.set_diff_ns_id(ns_id)
	state.diff_ns_id = ns_id
end

function M.get_output_buf()
	return state.output_buf
end

return M
