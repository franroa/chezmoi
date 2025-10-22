local M = {}

local highlights = require("ui.highlights")
local utils = require("core.utils")

function M.get_pipeline_steps(source_bufnr, components, all_chains_by_key)
	if not components or not all_chains_by_key then
		return nil
	end

	local all_chains_with_data = {}
	for _, chain_keys in ipairs(all_chains_by_key) do
		local final_chain = {}
		for _, key in ipairs(chain_keys) do
			local node = components[key]
			if node then
				table.insert(final_chain, {
					key = key,
					label = " " .. node.type .. " (" .. node.label .. ")",
					source_line = node.line,
					color = node.color or "Comment",
					original_type = node.type,
					original_label = node.label,
					content = node.content,
					original_block_content = node.original_block_content,
				})
			end
		end
		table.insert(all_chains_with_data, final_chain)
	end

	local chains_by_start = {}
	for _, chain in ipairs(all_chains_with_data) do
		if #chain > 0 then
			local start_label = chain[1].label
			if not chains_by_start[start_label] then
				chains_by_start[start_label] = {}
			end
			table.insert(chains_by_start[start_label], chain)
		end
	end

	return chains_by_start
end

function M.create_pipeline_diagram(source_bufnr, components, all_chains_by_key)
	local groups = M.get_pipeline_steps(source_bufnr, components, all_chains_by_key)
	if groups == nil or vim.tbl_isempty(groups) then
		vim.notify("No pipelines found to visualize.", vim.log.levels.WARN)
		return
	end

	local pipeline_hls = highlights.tokyonight_futuristic_hls
	local process_icons = {
		source = "",
		process = "",
		write = "󰒍",
		relabel = "",
		scrape = "󰥟",
		remote_write = "󰛶",
		file_match = "󰈞",
		file = "󰈞",
		default = "",
	}

	local arrow_chars =
		{ h = "─", v = "│", bl = "└", br = "┘", tr = "┐", arrow = "►", up = "▲", down = "▼" }
	local arrow = " " .. string.rep(arrow_chars.h, 2) .. arrow_chars.arrow .. " "

	local final_content, box_metadata, drawn_node_coords = {}, {}, {}
	local sorted_group_keys = {}
	for k in pairs(groups) do
		table.insert(sorted_group_keys, k)
	end
	table.sort(sorted_group_keys)

	local function center_text(text, width)
		local text_width = vim.fn.strwidth(text)
		if text_width >= width then
			return text
		end
		local padding_total = width - text_width
		local padding_left = math.floor(padding_total / 2)
		local padding_right = math.ceil(padding_total / 2)
		return string.rep(" ", padding_left) .. text .. string.rep(" ", padding_right)
	end

	local max_diagram_width = 0

	for _, key in ipairs(sorted_group_keys) do
		local group = groups[key]
		local max_text_widths = {}
		local icon_part_width = 4 -- icon col width

		-- Calculate max text widths for each column
		for _, chain in ipairs(group) do
			for j, box_data in ipairs(chain) do
				local text_width =
					math.max(vim.fn.strwidth(box_data.original_type), vim.fn.strwidth(box_data.original_label))
				max_text_widths[j] = math.max(max_text_widths[j] or 0, text_width)
			end
		end

		local max_screen_widths = {}
		for j, text_width in ipairs(max_text_widths) do
			max_screen_widths[j] = icon_part_width + 1 + (text_width + 2)
		end

		for i, chain_data in ipairs(group) do
			local top_parts, type_parts, name_parts, bottom_parts = {}, {}, {}, {}
			local current_col_disp = 0 -- DISPLAY width, not bytes
			local row_start_line = #final_content + 1

			-- Vertical connections for later chains
			if i > 1 then
				local parent_box_width = max_screen_widths[1]
				local gap_width = vim.fn.strwidth(arrow)
				local indent_width = parent_box_width + gap_width
				local center_col_of_parent = math.floor(parent_box_width / 2)
				local line1_content = string.rep(" ", center_col_of_parent) .. arrow_chars.v
				local h_line_len = indent_width - center_col_of_parent - 1 - 2
				if h_line_len < 0 then
					h_line_len = 0
				end
				local line2_content = string.rep(" ", center_col_of_parent)
					.. arrow_chars.bl
					.. string.rep(arrow_chars.h, h_line_len)
					.. arrow_chars.arrow
					.. " "
				table.insert(top_parts, line1_content .. string.rep(" ", indent_width - vim.fn.strwidth(line1_content)))
				table.insert(type_parts, line2_content)
				table.insert(name_parts, string.rep(" ", indent_width))
				table.insert(bottom_parts, string.rep(" ", indent_width))
				current_col_disp = indent_width
			end

			for j = (i == 1 and 1 or 2), #chain_data do
				local box_data = chain_data[j]
				local box_key = box_data.key

				-- Merge arrows to already drawn nodes
				if drawn_node_coords[box_key] then
					local target_coords = drawn_node_coords[box_key]
					local distance = target_coords.start_col - current_col_disp
					if distance < 2 then
						distance = 2
					end
					local h_line = string.rep(arrow_chars.h, distance - 2)
					local type_part_base = " " .. h_line
					local type_part, blank_merge_space, top_part, bottom_part
					if target_coords.line < row_start_line then
						type_part = type_part_base .. arrow_chars.br
						top_part = string.rep(" ", distance - 1) .. arrow_chars.up
						bottom_part = string.rep(" ", distance)
					else
						type_part = type_part_base .. arrow_chars.tr
						top_part = string.rep(" ", distance)
						bottom_part = string.rep(" ", distance - 1) .. arrow_chars.down
					end
					blank_merge_space = string.rep(" ", distance)
					table.insert(top_parts, top_part)
					table.insert(type_parts, type_part)
					table.insert(name_parts, blank_merge_space)
					table.insert(bottom_parts, bottom_part)
					current_col_disp = current_col_disp + distance
					break
				end

				-- Build box
				local process_name = box_data.original_type:match("%.([^.]+)$") or box_data.original_type
				local icon = process_icons[process_name] or process_icons.default
				local text_part_width = max_text_widths[j]
				local is_overridden =
					utils.overridden_components[box_data.original_type .. "-" .. box_data.original_label]

				local centered_type = center_text(box_data.original_type, text_part_width)
				local centered_label = center_text(box_data.original_label, text_part_width)
				local centered_icon = center_text(icon, icon_part_width - 2)
				local icon_col_2_content = is_overridden and center_text("🧪", icon_part_width)
					or string.rep(" ", icon_part_width)

				local text_padding_char = "─"
				local icon_padding_char = "─"

				local t_part = "┌"
					.. string.rep(icon_padding_char, icon_part_width)
					.. "┬"
					.. string.rep(text_padding_char, text_part_width + 2)
					.. "┐"
				local l1_part = "│ " .. centered_icon .. " │ " .. centered_type .. " │"
				local l2_part = "│" .. icon_col_2_content .. "│ " .. centered_label .. " │"
				local b_part = "└"
					.. string.rep(icon_padding_char, icon_part_width)
					.. "┴"
					.. string.rep(text_padding_char, text_part_width + 2)
					.. "┘"

				table.insert(top_parts, t_part)
				table.insert(type_parts, l1_part)
				table.insert(name_parts, l2_part)
				table.insert(bottom_parts, b_part)

				local box_disp_length = vim.fn.strwidth(l1_part)
				table.insert(box_metadata, {
					key = box_data.key,
					label = box_data.original_label,
					line_in_diagram = row_start_line,
					start_col = current_col_disp,
					end_col = current_col_disp + box_disp_length - 1,
					source_line = box_data.source_line,
					color = box_data.color,
					original_type = box_data.original_type,
					original_label = box_data.original_label,
					content = box_data.content,
					original_block_content = box_data.original_block_content,
					is_overridden = is_overridden,
				})
				drawn_node_coords[box_key] = { line = row_start_line, start_col = current_col_disp }
				current_col_disp = current_col_disp + box_disp_length

				-- Add arrow if needed
				if j < #chain_data then
					local next_box_key = chain_data[j + 1].key
					if not drawn_node_coords[next_box_key] then
						local arrow_w = vim.fn.strwidth(arrow)
						local arrow_space = string.rep(" ", arrow_w)
						table.insert(top_parts, arrow_space)
						table.insert(type_parts, arrow)
						table.insert(name_parts, arrow_space)
						table.insert(bottom_parts, arrow_space)
						current_col_disp = current_col_disp + arrow_w
					end
				end
			end

			max_diagram_width = math.max(max_diagram_width, current_col_disp)
			table.insert(final_content, table.concat(top_parts))
			table.insert(final_content, table.concat(type_parts))
			table.insert(final_content, table.concat(name_parts))
			table.insert(final_content, table.concat(bottom_parts))
			table.insert(final_content, "")
		end
	end

	-- Center diagram
	local win_width = vim.api.nvim_win_get_width(0)
	local padding_left_total = math.floor(math.max(0, (win_width - max_diagram_width) / 2))
	local padding_str = string.rep(" ", padding_left_total)

	local centered_content = {}
	for _, line in ipairs(final_content) do
		table.insert(centered_content, padding_str .. line)
	end

	return centered_content, box_metadata
end

return M
