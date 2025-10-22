local M = {}

local utils = require("core.utils")

local process_icons = {
	source = "",
	process = "",
	write = "✍",
	relabel = "",
	scrape = "",
	remote_write = "",
	file_match = "",
	file = "",
	default = "",
}

local function create_box_parts(box_data, max_text_widths, j, is_overridden)
	local process_name = box_data.original_type:match("%.([^.]+)$") or box_data.original_type
	local icon = process_icons[process_name] or process_icons.default
	local text_part_width = max_text_widths[j]
	local icon_part_width = 4

	local centered_type = utils.center_text(box_data.original_type, text_part_width)
	local centered_label = utils.center_text(box_data.original_label, text_part_width)
	local centered_icon = utils.center_text(icon, icon_part_width - 2)
	local icon_col_2_content = is_overridden and utils.center_text("🧪", icon_part_width)
		or string.rep(" ", icon_part_width)

	local text_padding = string.rep("─", text_part_width + 2)
	local icon_padding = string.rep("─", icon_part_width)

	return {
		top = "┌" .. icon_padding .. "┬" .. text_padding .. "┐",
		line1 = "│ " .. centered_icon .. " │ " .. centered_type .. " │",
		line2 = "│" .. icon_col_2_content .. "│ " .. centered_label .. " │",
		bottom = "└" .. icon_padding .. "┴" .. text_padding .. "┘",
	}
end

local function calculate_max_widths(group)
	local max_text_widths = {}
	for _, chain in ipairs(group) do
		for j, box_data in ipairs(chain) do
			local text_width =
				math.max(vim.fn.strwidth(box_data.original_type), vim.fn.strwidth(box_data.original_label))
			max_text_widths[j] = math.max(max_text_widths[j] or 0, text_width)
		end
	end
	return max_text_widths
end

-- Convert display column to byte index (popup safe)
local function wincol_to_byteidx(line, wincol)
	local byteidx = 0
	local dispcol = 0
	while byteidx < #line do
		local char = vim.fn.strcharpart(line, dispcol, 1)
		local char_width = vim.fn.strdisplaywidth(char)
		if dispcol >= wincol then
			break
		end
		dispcol = dispcol + char_width
		byteidx = byteidx + #char
	end
	return byteidx
end

function M.calculate_actual_box_position(line, box, components, opts)
	opts = opts or {}
	local col_offset = opts.col_offset or 0 -- Adjust for popup padding

	-- Auto-adjust popup padding if a popup window is provided
	if opts.popup_win_id then
		local cfg = vim.api.nvim_win_get_config(opts.popup_win_id)
		if cfg.col then
			local border_size = (cfg.border and #cfg.border > 0) and 1 or 0
			col_offset = cfg.col[false] and (cfg.col[false] + border_size) or col_offset
		end
	end

	local box_data = components[box.key]
	if not box_data then
		return nil
	end

	local search_text = (box_data.original_label and box_data.original_label ~= "") and box_data.original_label
		or box_data.original_type
	if not search_text or search_text == "" then
		return nil
	end

	-- Find the label in the line
	local label_sb, label_eb = string.find(line, search_text, 1, true)
	if not label_sb then
		return nil
	end

	-------------------------------------------------------------------
	-- Left edge: first pipe "│" (before icons)
	-------------------------------------------------------------------
	local first_pipe_b = line:find("│")
	if not first_pipe_b then
		return nil
	end
	local start_col = vim.fn.strdisplaywidth(line:sub(1, first_pipe_b - 1))

	-------------------------------------------------------------------
	-- Right edge: last pipe "│" (after label)
	-------------------------------------------------------------------
	local last_pipe_b
	do
		local idx = 1
		while true do
			local next_b = line:find("│", idx, true)
			if not next_b then
				break
			end
			last_pipe_b = next_b
			idx = next_b + 1
		end
	end
	if not last_pipe_b then
		return nil
	end
	local end_col = vim.fn.strdisplaywidth(line:sub(1, last_pipe_b))

	-------------------------------------------------------------------
	-- Apply popup offset
	-------------------------------------------------------------------
	local start_wincol = start_col - col_offset
	local end_wincol = end_col - col_offset

	-- Convert to byte indexes (safe for multi-byte chars)
	local start_byte = wincol_to_byteidx(line, start_col)
	local end_byte = wincol_to_byteidx(line, end_col)

	return {
		start_col = start_wincol,
		end_col = end_wincol,
		start_byte = start_byte,
		end_byte = end_byte,
	}
end

local function create_connector_lines(parent_box_width, gap_width, arrow_chars)
	local center_col_of_parent = math.floor(parent_box_width / 2)
	local indent_width = parent_box_width + gap_width
	local h_line_len = math.max(0, indent_width - center_col_of_parent - 1 - 2)

	local line1_content = string.rep(" ", center_col_of_parent) .. arrow_chars.v
	local line2_content = string.rep(" ", center_col_of_parent)
		.. arrow_chars.bl
		.. string.rep(arrow_chars.h, h_line_len)
		.. arrow_chars.arrow
		.. " "

	return {
		line1 = line1_content .. string.rep(" ", indent_width - vim.fn.strwidth(line1_content)),
		line2 = line2_content,
		blank = string.rep(" ", indent_width),
		indent_width = indent_width,
	}
end

function M.build_horizontal_diagram_content(groups, components)
	local arrow_chars = { h = "─", v = "│", bl = "└", br = "┘", tr = "┐", arrow = "►" }
	local arrow = " " .. string.rep(arrow_chars.h, 2) .. arrow_chars.arrow .. " "

	local final_content = {}
	local box_metadata = {}
	local drawn_node_coords = {}

	local sorted_group_keys = {}
	for k in pairs(groups) do
		table.insert(sorted_group_keys, k)
	end
	table.sort(sorted_group_keys)

	for group_idx, key in ipairs(sorted_group_keys) do
		local group = groups[key]
		local max_text_widths = calculate_max_widths(group)
		local max_screen_widths = {}

		for j, text_width in ipairs(max_text_widths) do
			max_screen_widths[j] = 4 + 1 + (text_width + 2) -- icon_part_width + separator + text
		end

		for i, chain_data in ipairs(group) do
			local top_parts = { string.rep(" ", 2) }
			local type_parts = { string.rep(" ", 2) }
			local name_parts = { string.rep(" ", 2) }
			local bottom_parts = { string.rep(" ", 2) }

			local current_byte_col = 2
			local row_start_line = #final_content + 1

			-- Add connector lines for chains after the first
			if i > 1 then
				local connector = create_connector_lines(max_screen_widths[1], string.len(arrow), arrow_chars) -- Use byte length
				table.insert(top_parts, connector.line1)
				table.insert(type_parts, connector.line2)
				table.insert(name_parts, connector.blank)
				table.insert(bottom_parts, connector.blank)
				current_byte_col = current_byte_col + connector.indent_width
			end

			-- Process each box in the chain
			for j = (i == 1 and 1 or 2), #chain_data do
				local box_data = chain_data[j]
				local box_key = box_data.key

				-- Check if this component was already drawn
				if drawn_node_coords[box_key] then
					-- Create merge connector
					local target_coords = drawn_node_coords[box_key]
					local distance = math.max(2, target_coords.start_col - current_byte_col)
					local h_line = string.rep(arrow_chars.h, distance - 2)

					local connector_parts = {
						type_part = " "
							.. h_line
							.. (target_coords.line < row_start_line and arrow_chars.br or arrow_chars.tr),
						top_part = string.rep(" ", target_coords.line < row_start_line and distance - 1 or distance),
						bottom_part = string.rep(" ", target_coords.line < row_start_line and distance or distance - 1),
					}

					if target_coords.line < row_start_line then
						connector_parts.top_part = connector_parts.top_part:sub(1, -2) .. "▲"
					else
						connector_parts.bottom_part = connector_parts.bottom_part:sub(1, -2) .. "▼"
					end

					table.insert(top_parts, connector_parts.top_part)
					table.insert(type_parts, connector_parts.type_part)
					table.insert(name_parts, string.rep(" ", distance))
					table.insert(bottom_parts, connector_parts.bottom_part)

					current_byte_col = current_byte_col + distance
					break
				end

				-- Create new box
				local is_overridden =
					utils.overridden_components[box_data.original_type .. "-" .. box_data.original_label]
				local box_parts = create_box_parts(box_data, max_text_widths, j, is_overridden)

				table.insert(top_parts, box_parts.top)
				table.insert(type_parts, box_parts.line1)
				table.insert(name_parts, box_parts.line2)
				table.insert(bottom_parts, box_parts.bottom)

				local box_byte_length = string.len(box_parts.line1) -- Use byte length, not display width

				-- We'll calculate the actual positions after the line is built
				-- For now, store placeholder values
				local icon_line = row_start_line + 2 -- Icon is on the second content line (1-based)
				local icon_col = 0 -- Will be calculated after line is complete
				local final_start_col = 0 -- Will be calculated after line is complete
				local final_end_col = 0 -- Will be calculated after line is complete

				table.insert(box_metadata, {
					key = box_data.key,
					label = box_data.original_label,
					line_in_diagram = row_start_line,
					start_col = final_start_col,
					end_col = final_end_col,
					icon_line = icon_line,
					icon_col = icon_col,
					source_line = box_data.source_line,
					color = box_data.color,
					original_type = box_data.original_type,
					original_label = box_data.original_label,
					content = box_data.content,
					original_block_content = box_data.original_block_content,
					is_overridden = is_overridden,
				})

				drawn_node_coords[box_key] = { line = row_start_line, start_col = current_byte_col }
				current_byte_col = current_byte_col + box_byte_length

				-- Add arrow connector to next box
				if j < #chain_data then
					local next_box_key = chain_data[j + 1].key
					if not drawn_node_coords[next_box_key] then
						local arrow_space = string.rep(" ", string.len(arrow)) -- Use byte length
						table.insert(top_parts, arrow_space)
						table.insert(type_parts, arrow)
						table.insert(name_parts, arrow_space)
						table.insert(bottom_parts, arrow_space)
						current_byte_col = current_byte_col + string.len(arrow) -- Use byte length
					end
				end
			end

			-- Add completed parts to final content
			table.insert(final_content, table.concat(top_parts))
			local type_line = table.concat(type_parts)
			table.insert(final_content, type_line)
			local name_line = table.concat(name_parts)
			table.insert(final_content, name_line)
			table.insert(final_content, table.concat(bottom_parts))

			-- Now calculate actual byte positions for all boxes in this row
			for _, box in ipairs(box_metadata) do
				if box.line_in_diagram == row_start_line then
					local line_to_search
					if box.original_label and box.original_label ~= "" then
						line_to_search = name_line
					else
						line_to_search = type_line
					end
					local actual_positions = M.calculate_actual_box_position(line_to_search, box, components)
					if actual_positions then
						box.icon_col = actual_positions.icon_col
						box.start_col = actual_positions.start_col
						box.end_col = actual_positions.end_col
					end
				end
			end
		end

		-- Add spacing between groups
		if group_idx < #sorted_group_keys then
			table.insert(final_content, "")
		end
	end

	return final_content, box_metadata
end

return M
