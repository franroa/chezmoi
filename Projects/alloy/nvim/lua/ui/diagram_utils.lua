local M = {}

local utils = require("core.utils")

-- map popup-local display column -> byte index (0-based)
local function wincol_to_byte(line, target_col)
	if not line or target_col <= 0 then
		return 0
	end
	local col = 0
	local i = 1
	while i <= #line do
		local b = line:byte(i)
		local len = (b < 0x80) and 1 or (b < 0xE0 and 2 or (b < 0xF0 and 3 or 4))
		local ch = line:sub(i, i + len - 1)
		local w = vim.fn.strdisplaywidth(ch)
		if col + w > target_col then
			return i - 1
		end
		col = col + w
		i = i + len
	end
	return #line
end

-- map byte index -> popup-local display column
local function byte_to_wincol(line, byte_idx0)
	if not line or line == "" or byte_idx0 <= 0 then
		return 0
	end
	-- safe slice up to the given byte
	local prefix = line:sub(1, byte_idx0)
	return vim.fn.strdisplaywidth(prefix)
end

function M.get_box_at_cursor(win_id, metadata, diagram_type)
	if not utils.validate_window(win_id) then
		return nil, nil
	end

	local pos = vim.api.nvim_win_get_cursor(win_id)
	local cursor_line, cursor_col_bytes = pos[1], pos[2] -- line is 1-based, col is 0-based

	-- Convert byte position to display column
	local line = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win_id), cursor_line - 1, cursor_line, false)[1]
	local cursor_col_disp = cursor_col_bytes
	if line then
		cursor_col_disp = byte_to_wincol(line, cursor_col_bytes)
	end

	for i, box in ipairs(metadata) do
		if diagram_type == "horizontal" then
			-- Horizontal diagram: box spans multiple lines (borders + content)
			local box_top = box.line_in_diagram + 1 -- first content line
			local box_bottom = box.line_in_diagram + 4 -- last content line

			if
				cursor_line >= box_top
				and cursor_line <= box_bottom
				and cursor_col_disp >= box.start_col
				and cursor_col_disp <= box.end_col
			then
				return i, box
			end
		elseif diagram_type == "vertical_list" then
			-- Vertical list: single line
			if
				cursor_line == box.line_in_diagram
				and cursor_col_disp >= box.start_col
				and cursor_col_disp <= box.end_col
			then
				return i, box
			end
		end
	end

	return nil, nil
end

function M.jump_to_component(state, key)
	for _, box in ipairs(state.box_metadata) do
		if box.key == key then
			local win_id = state.win_id
			if not utils.validate_window(win_id) then
				return false
			end

			if state.type == "horizontal" then
				M.scroll_to_box_horizontal(state, box)
			end

			local line, col
			if state.type == "horizontal" then
				if box.icon_line and box.icon_col then
					line = box.icon_line
					local line_content = vim.api.nvim_buf_get_lines(state.buf, line - 1, line, false)[1] or ""
					-- wincol_to_byte expects a display column; subtract 1 to convert to 0-based and clamp
					col = math.max(0, wincol_to_byte(line_content, box.icon_col) - 1)
				else
					line = box.line_in_diagram + 2
					local line_content = vim.api.nvim_buf_get_lines(state.buf, line - 1, line, false)[1] or ""
					-- start_col is a display column; +1 to target inner content, then convert and make 0-based
					col = math.max(0, wincol_to_byte(line_content, box.start_col + 1) - 1)
				end
			else
				line = box.line_in_diagram
				col = 2
			end

			vim.api.nvim_win_set_cursor(win_id, { line, col })
			vim.fn.win_execute(win_id, "normal! zz")
			return true
		end
	end

	return false
end

function M.scroll_to_box_horizontal(state, box)
	if not utils.validate_window(state.win_id) then
		return
	end

	local win_id = state.win_id
	local view = vim.fn.winsaveview()
	local win_width = vim.api.nvim_win_get_width(win_id)

	if state.total_content_width and state.total_content_width > win_width then
		local max_leftcol = state.total_content_width - win_width

		-- Center on the icon position for better visibility
		local center_col = box.icon_col or (box.start_col + math.floor((box.end_col - box.start_col) / 2))
		local desired_leftcol = center_col - math.floor(win_width / 2)

		view.leftcol = math.max(0, math.min(desired_leftcol, max_leftcol))
	else
		view.leftcol = 0
	end

	vim.fn.winrestview(view)
end

function M.get_current_pipeline_index(state)
	local _, box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)
	if not box then
		return nil
	end

	for i, pipeline in ipairs(state.pipelines) do
		if vim.tbl_contains(pipeline, box.key) then
			return i
		end
	end

	return nil
end

function M.find_pipeline_start_boxes(state)
	local pipeline_start_boxes = {}

	if #state.pipelines > 0 then
		local start_keys = {}
		for _, p in ipairs(state.pipelines) do
			if #p > 0 then
				start_keys[p[1]] = true
			end
		end

		for _, box in ipairs(state.box_metadata) do
			if start_keys[box.key] then
				table.insert(pipeline_start_boxes, box)
			end
		end

		table.sort(pipeline_start_boxes, function(a, b)
			return a.line_in_diagram < b.line_in_diagram
		end)
	end

	return pipeline_start_boxes
end

function M.navigate_pipeline_components(state, direction)
	if state.nav_mode ~= "component" then
		return false
	end

	local _, current_box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)
	if not (current_box and state.focused_pipeline_index) then
		return false
	end

	local current_pipeline = state.pipelines[state.focused_pipeline_index]
	local pos_in_pipeline = nil

	for i, key in ipairs(current_pipeline) do
		if key == current_box.key then
			pos_in_pipeline = i
			break
		end
	end

	if not pos_in_pipeline then
		return false
	end

	local target_pos
	if direction == "next" then
		if pos_in_pipeline < #current_pipeline then
			target_pos = pos_in_pipeline + 1
		else
			-- Cycle to first component when at end
			target_pos = 1
		end
	elseif direction == "prev" then
		if pos_in_pipeline > 1 then
			target_pos = pos_in_pipeline - 1
		else
			-- Cycle to last component when at start
			target_pos = #current_pipeline
		end
	end

	if target_pos then
		return M.jump_to_component(state, current_pipeline[target_pos])
	end

	return false
end

function M.navigate_pipeline_starts(state, direction, pipeline_start_boxes)
	if #pipeline_start_boxes == 0 then
		return false
	end

	-- Get the current box at cursor
	local _, current_box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)
	if not current_box then
		-- If no current box, jump to first or last depending on direction
		if direction == "next" then
			return M.jump_to_component(state, pipeline_start_boxes[1].key)
		else
			return M.jump_to_component(state, pipeline_start_boxes[#pipeline_start_boxes].key)
		end
	end

	-- Find the index of current box in pipeline_start_boxes
	local current_block_index = nil
	for i, box in ipairs(pipeline_start_boxes) do
		if box.key == current_box.key then
			current_block_index = i
			break
		end
	end

	if direction == "next" then
		if current_block_index then
			-- Current box is a pipeline start, go to next
			local next_idx = (current_block_index % #pipeline_start_boxes) + 1
			return M.jump_to_component(state, pipeline_start_boxes[next_idx].key)
		else
			-- Current box is not a pipeline start, find the next pipeline start
			local pos = vim.api.nvim_win_get_cursor(state.win_id)
			local current_line = pos[1]
			for i, box in ipairs(pipeline_start_boxes) do
				if box.line_in_diagram > current_line then
					return M.jump_to_component(state, box.key)
				end
			end
			-- If no next pipeline found, go to first
			return M.jump_to_component(state, pipeline_start_boxes[1].key)
		end
	elseif direction == "prev" then
		if current_block_index then
			-- Current box is a pipeline start, go to previous
			local prev_idx = ((current_block_index - 2 + #pipeline_start_boxes) % #pipeline_start_boxes) + 1
			return M.jump_to_component(state, pipeline_start_boxes[prev_idx].key)
		else
			-- Current box is not a pipeline start, find the previous pipeline start
			local pos = vim.api.nvim_win_get_cursor(state.win_id)
			local current_line = pos[1]
			for i = #pipeline_start_boxes, 1, -1 do
				if pipeline_start_boxes[i].line_in_diagram < current_line then
					return M.jump_to_component(state, pipeline_start_boxes[i].key)
				end
			end
			-- If no previous pipeline found, go to last
			return M.jump_to_component(state, pipeline_start_boxes[#pipeline_start_boxes].key)
		end
	end

	return false
end

function M.scroll_source_to_component(state, box)
	if not box or not box.source_line or not state.source_bufnr then
		return false
	end

	local source_win_id = vim.fn.bufwinid(state.source_bufnr)
	if source_win_id == -1 then
		return false
	end

	-- Scroll the .alloy file to show the component at the top of the visible window
	local original_scrolloff = vim.api.nvim_win_get_option(source_win_id, "scrolloff")
	vim.api.nvim_win_set_option(source_win_id, "scrolloff", 0)
	vim.api.nvim_win_set_cursor(source_win_id, { box.source_line, 0 })
	vim.fn.win_execute(source_win_id, "normal! zt") -- zt = scroll to top of window
	vim.api.nvim_win_set_option(source_win_id, "scrolloff", original_scrolloff)

	return true
end

return M
