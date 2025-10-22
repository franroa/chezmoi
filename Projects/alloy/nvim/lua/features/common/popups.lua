local M = {}

local popup = require("ui.popup")
local tester = require("features.testing.utils.e2e_runner")

function M.create_selection_popup(items, opts, on_confirm)
	return popup.create_selection_popup(items, opts, on_confirm)
end

function M.create_help_popup(diagram_state, diagram_type)
	if diagram_state.help_popup_win_id and vim.api.nvim_win_is_valid(diagram_state.help_popup_win_id) then
		vim.api.nvim_win_close(diagram_state.help_popup_win_id, true)
		diagram_state.help_popup_win_id = nil
	end

	local keymaps
	if diagram_type == "vertical_list" then
		-- disable Tab / S-Tab in vertical diagram by omitting it from help list
		keymaps = {
			{ "<Tab>/<S-Tab>", "Cycle through components" },
			{ "o", "Add new component below cursor" },
			{ "<CR>", "Jump to component in source" },
			{ "<C-u>/<C-d>", "Scroll source buffer" },
			{ "<leader>k", "Show component code preview" },
			{ "f", "Set new filter" },
			{ "c", "Clear filter" },
			{ "<leader>t", "Run E2E test for the whole file" },
			{ "<leader>te", "Edit this component's override file" },
			{ "q", "Close diagram / popup" },
			{ "g?", "Show this help menu" },
		}
	else -- "horizontal"
		keymaps = {
			{ "<Tab>/<S-Tab>", "Cycle through components/pipelines" },
			{ "p", "Focus/unfocus pipeline" },
			{ "<CR>", "Go to Definition (or show Test Summary if failed)" },
			{ "<C-u>/<C-d>", "Scroll source buffer" },
			{ "<leader>k", "Show component code (or Diff if tested)" },
			{ "<leader>t", "Run E2E test for the whole file" },
			{ "<leader>te", "Edit this component's override file" },
			{ "q", "Close diagram / popup" },
			{ "g?", "Show this help menu" },
		}
	end

	local max_key_len = 0
	for _, map in ipairs(keymaps) do
		max_key_len = math.max(max_key_len, vim.fn.strwidth(map[1]))
	end

	local help_content = {}
	for _, map in ipairs(keymaps) do
		local key, desc = map[1], map[2]
		local padding = string.rep(" ", max_key_len - vim.fn.strwidth(key))
		table.insert(help_content, string.format(" %s%s │ %s", key, padding, desc))
	end

	local width = 0
	for _, line in ipairs(help_content) do
		width = math.max(width, vim.fn.strwidth(line))
	end
	width = width + 4

	local popup_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, help_content)
	vim.bo[popup_buf].modifiable = false

	local help_win_id = popup.create_styled_popup(popup_buf, "Commands", width, #help_content, {
		relative = "win",
		win = diagram_state.win_id,
		row = 2,
		col = 5,
		zindex = 150,
	})

	local function close_help()
		if vim.api.nvim_win_is_valid(help_win_id) then
			vim.api.nvim_win_close(help_win_id, true)
		end
		diagram_state.help_popup_win_id = nil
	end

	local keymaps = require("main.keymaps")
	keymaps.register({
		{
			id = "help-close-q",
			mode = "n",
			lhs = "q",
			rhs = close_help,
			opts = { buffer = popup_buf, silent = true },
			desc = "Close help",
		},
		{
			id = "help-close-g?",
			mode = "n",
			lhs = "g?",
			rhs = close_help,
			opts = { buffer = popup_buf, silent = true },
			desc = "Close help",
		},
	})

	diagram_state.help_popup_win_id = help_win_id
end

function M.open_component_popup(diagram_state, box, opts)
	opts = opts or {}
	if not (box and (box.content or box.is_overridden)) then
		return
	end

	local content_lines, popup_title, filetype
	local highlights = {}
	local is_diff_view = box.is_overridden

	if is_diff_view then
		popup_title = "Component Diff: " .. box.original_type .. "." .. box.original_label
		filetype = "diff"
		local original_code = box.original_block_content
		local override_code = tester.get_override_content(box.original_type .. "-" .. box.original_label)
		if not override_code then
			content_lines = { "Error: Could not load override file." }
		else
			local original_file = vim.fn.tempname()
			local override_file = vim.fn.tempname()
			vim.fn.writefile(vim.split(original_code, "\n"), original_file)
			vim.fn.writefile(vim.split(override_code, "\n"), override_file)
			local diff_result = vim.fn.system({ "diff", "-u", original_file, override_file })
			vim.fn.delete(original_file)
			vim.fn.delete(override_file)
			content_lines = vim.split(diff_result, "\n")
			for i, line in ipairs(content_lines) do
				if line:sub(1, 1) == "+" and not line:match("^%+%+%+") then
					table.insert(highlights, { line = i, hl = "AlloyDiffAdd" })
				elseif line:sub(1, 1) == "-" and not line:match("^%-%-%-") then
					table.insert(highlights, { line = i, hl = "AlloyDiffDelete" })
				end
			end
		end
	else
		popup_title = "Component Code: " .. box.original_type .. "." .. box.original_label
		filetype = "river"
		content_lines = vim.split(box.content, "\n")
	end

	local popup_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[popup_buf].filetype = filetype
	vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, content_lines)

	local win_opts = { style = "minimal", border = "rounded", title = popup_title, title_pos = "center", zindex = 100 }
	if opts.layout == "horizontal_manual" then
		local diagram_win_config = vim.api.nvim_win_get_config(opts.parent_win_id)
		local popup_top_row = diagram_win_config.row + box.line_in_diagram + 3
		win_opts.relative = "editor"
		win_opts.width = vim.o.columns
		win_opts.height = math.max(1, vim.o.lines - popup_top_row - 1)
		win_opts.row = popup_top_row
		win_opts.col = 0
		win_opts.focusable = true
	else
		local width = 0
		for _, line in ipairs(content_lines) do
			width = math.max(width, vim.fn.strwidth(line))
		end
		win_opts.width = math.min(width + 4, 120)
		win_opts.height = math.min(#content_lines, 25)
		win_opts.relative = "cursor"
		win_opts.row = 1
		win_opts.col = 3
		win_opts.focusable = false
	end

	local popup_win_id = vim.api.nvim_open_win(popup_buf, true, win_opts)
	for _, hl_data in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(popup_buf, -1, hl_data.hl, hl_data.line - 1, 0, -1)
	end

	local function close_component_popup()
		if vim.api.nvim_win_is_valid(popup_win_id) then
			vim.api.nvim_win_close(popup_win_id, true)
		end
		if diagram_state and diagram_state.win_id and vim.api.nvim_win_is_valid(diagram_state.win_id) then
			vim.api.nvim_set_current_win(diagram_state.win_id)
		end
		diagram_state.popup_win_id = nil
	end

	local keymaps = require("main.keymaps")
	keymaps.register({
		{
			id = "component-popup-close",
			mode = "n",
			lhs = "q",
			rhs = close_component_popup,
			opts = { buffer = popup_buf, silent = true },
			desc = "Close popup",
		},
	})
	diagram_state.popup_win_id = popup_win_id
end

return M
