local M = {}

local highlights = require("ui.highlights")

local function setup_buffer(buf, opts)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = opts.filetype or "markdown"
end

local function calculate_dimensions(content, opts)
	local width = 0
	for _, line in ipairs(content) do
		width = math.max(width, vim.fn.strwidth(line))
	end
	width = math.min(width + 4, vim.o.columns - 10)

	return {
		width = width,
		height = #content,
	}
end

local function calculate_position(width, height, opts)
	local row = opts.row or math.floor((vim.o.lines - height) / 2)
	local col = opts.col or math.floor((vim.o.columns - width) / 2)

	return { row = row, col = col }
end

local function setup_keymaps(buf, win, opts)
	M.register_popup_close_keymaps(buf, function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, opts.keymaps)
end

function M.register_popup_close_keymaps(buf, close_function, extra_keymaps)
	local keymaps = require("main.keymaps")
	local maps = {
		{
			id = "popup-close-q",
			mode = "n",
			lhs = "q",
			rhs = close_function,
			opts = { buffer = buf, nowait = true },
			desc = "Close popup",
		},
		{
			id = "popup-close-esc",
			mode = "n",
			lhs = "<Esc>",
			rhs = close_function,
			opts = { buffer = buf, nowait = true },
			desc = "Close popup",
		},
	}
	if extra_keymaps then
		for key, func in pairs(extra_keymaps) do
			table.insert(
				maps,
				{
					id = "popup-extra-" .. key,
					mode = "n",
					lhs = key,
					rhs = func,
					opts = { buffer = buf, nowait = true },
					desc = "Popup custom",
				}
			)
		end
	end
	keymaps.register(maps)
end

function M.create_popup(content, opts)
	opts = opts or {}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

	local dims = calculate_dimensions(content, opts)
	local pos = calculate_position(dims.width, dims.height, opts)

	local win_opts = {
		relative = "editor",
		style = "minimal",
		border = opts.border or "rounded",
		title = opts.title,
		title_pos = opts.title_pos or "center",
		width = dims.width,
		height = dims.height,
		zindex = 50,
		row = pos.row,
		col = pos.col,
	}

	local win = vim.api.nvim_open_win(buf, true, win_opts)
	vim.wo[win].winhighlight = "FloatBorder:PopupBorder"

	setup_buffer(buf, opts)
	setup_keymaps(buf, win, opts)

	return win, buf
end

local function calculate_relative_position(win_opts, width, height)
	if win_opts.relative == "win" and win_opts.win then
		local parent_width = vim.api.nvim_win_get_width(win_opts.win)
		win_opts.row = win_opts.row or 0
		win_opts.col = win_opts.col or math.floor((parent_width - width - 2) / 2)
	else
		win_opts.relative = "editor"
		win_opts.row = win_opts.row or 1
		win_opts.col = win_opts.col or math.floor((vim.o.columns - width - 2) / 2)
	end
end

function M.create_styled_popup(buf, title, width, height, opts)
	opts = opts or {}

	local pipeline_hls = highlights.tokyonight_futuristic_hls

	local win_opts = {
		style = "minimal",
		border = pipeline_hls.BorderChars or "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
		width = width,
		height = height,
		zindex = 50,
	}

	for k, v in pairs(opts) do
		win_opts[k] = v
	end

	calculate_relative_position(win_opts, width, height)

	local win_id = vim.api.nvim_open_win(buf, true, win_opts)
	vim.wo[win_id].winhighlight = "Normal:Normal,FloatBorder:DiagramBorder,FloatTitle:DiagramBoxStageHeader"

	return win_id
end

local function validate_parent_window(parent_win_id)
	return parent_win_id and vim.api.nvim_win_is_valid(parent_win_id)
end

local function prepare_selection_items(items)
	local lines = {}
	for _, item in ipairs(items) do
		table.insert(lines, "" .. item.display)
	end
	return lines
end

local function setup_selection_window(popup_win_id)
	vim.wo[popup_win_id].cursorline = true
	vim.wo[popup_win_id].number = false
	vim.wo[popup_win_id].relativenumber = false
end

local function create_cleanup_handler(popup_win_id, parent_win_id)
	return function()
		if vim.api.nvim_win_is_valid(popup_win_id) then
			vim.api.nvim_win_close(popup_win_id, true)
		end
		if vim.api.nvim_win_is_valid(parent_win_id) then
			vim.api.nvim_set_current_win(parent_win_id)
		end
	end
end

function M.create_selection_popup(items, opts, on_confirm)
	local parent_win_id = opts.parent_win_id

	if not validate_parent_window(parent_win_id) then
		return
	end

	local parent_config = vim.api.nvim_win_get_config(parent_win_id)
	local lines = prepare_selection_items(items)
	local height = #lines
	local width = 0

	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strwidth(line))
	end
	width = width + 4

	local buf = vim.api.nvim_create_buf(false, true)
	setup_buffer(buf, {})
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local popup_win_id = vim.api.nvim_open_win(buf, true, {
		relative = "win",
		win = parent_win_id,
		style = "minimal",
		border = "rounded",
		title = opts.prompt or "Select One",
		title_pos = "center",
		width = width,
		height = height,
		row = -height - 2,
		col = math.floor((parent_config.width - width) / 2),
		zindex = 200,
	})

	setup_selection_window(popup_win_id)
	local cleanup_and_close = create_cleanup_handler(popup_win_id, parent_win_id)

	local keymaps = require("main.keymaps")
	keymaps.register({
		{
			id = "popup-confirm",
			mode = "n",
			lhs = "<CR>",
			rhs = function()
				local cursor_pos = vim.api.nvim_win_get_cursor(popup_win_id)
				local selected_line_num = cursor_pos[1]
				local selected_item = items[selected_line_num]
				cleanup_and_close()
				if selected_item then
					on_confirm(selected_item)
				end
			end,
			opts = { buffer = buf, silent = true, nowait = true },
			desc = "Confirm selection",
		},
	})

	keymaps.register({
		{
			id = "popup-close-q",
			mode = "n",
			lhs = "q",
			rhs = cleanup_and_close,
			opts = { buffer = buf, silent = true, nowait = true },
			desc = "Close selection",
		},
		{
			id = "popup-close-esc",
			mode = "n",
			lhs = "<Esc>",
			rhs = cleanup_and_close,
			opts = { buffer = buf, silent = true, nowait = true },
			desc = "Close selection",
		},
	})
end

return M
