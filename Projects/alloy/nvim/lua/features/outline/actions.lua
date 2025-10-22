local M = {}

local state = require("features.common.state")
local parser = require("core.parser")
local diagram_utils = require("ui.diagram_utils")

function M.diagram_sync_save()
	local current_state = state.get_state()
	if not current_state or not current_state.source_bufnr then
		return
	end

	local diagram_buf = vim.api.nvim_get_current_buf()
	local source_bufnr = current_state.source_bufnr

	-- 1. Get the block of text from the diagram buffer
	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	local diagram_lines = vim.api.nvim_buf_get_lines(diagram_buf, 0, -1, false)

	local open_brace_line = -1
	for i = cursor_row, 1, -1 do
		if diagram_lines[i]:find("{") then
			open_brace_line = i
			break
		end
	end

	if open_brace_line == -1 then
		vim.notify("No Alloy block found around cursor to save.", vim.log.levels.WARN)
		return
	end

	local block_lines = {}
	local brace_depth = 0
	local started = false
	for i = open_brace_line, #diagram_lines do
		local line = diagram_lines[i]
		for char in line:gmatch(".") do
			if char == "{" then
				brace_depth = brace_depth + 1
				started = true
			elseif char == "}" then
				brace_depth = brace_depth - 1
			end
		end
		if started then
			table.insert(block_lines, line)
			if brace_depth == 0 then
				break
			end
		end
	end

	if #block_lines == 0 then
		vim.notify("Could not extract a valid block.", vim.log.levels.WARN)
		return
	end

	-- 2. Get pipeline context from the source buffer
	local components, all_chains_by_key, _ = parser.get_parsed_pipeline_data(source_bufnr)
	if not components then
		return
	end

	-- Find the component *before* the one being edited/added
	local box_before = nil
	local line_above_block = open_brace_line - 1
	while line_above_block > 1 do
		for _, meta in ipairs(current_state.box_metadata) do
			if meta.line_in_diagram == line_above_block then
				box_before = meta
				goto found_box_before
			end
		end
		line_above_block = line_above_block - 1
	end
	::found_box_before::

	if not box_before then
		vim.notify("Could not determine position in pipeline.", vim.log.levels.WARN)
		return
	end

	local target_chain = nil
	for _, chain in ipairs(all_chains_by_key) do
		if vim.tbl_contains(chain, box_before.key) then
			target_chain = chain
			break
		end
	end

	if not target_chain then
		vim.notify("Could not find pipeline for '" .. box_before.key .. "'.", vim.log.levels.WARN)
		return
	end

	-- 3. Transform the `forward_to` line
	for i, line in ipairs(block_lines) do
		if line:match("%s*forward_to%s*=") then
			local comment_content = line:match("/%*%s*(.-)%s*%*/")
			if comment_content then
				local target_key = nil
				if comment_content:match("loki.write") then
					for key, comp in pairs(components) do
						if comp.type == "loki.write" then
							target_key = key
							break
						end
					end
				elseif comment_content:match("other") then
					local box_before_idx = -1
					for idx, key in ipairs(target_chain) do
						if key == box_before.key then
							box_before_idx = idx
							break
						end
					end
					if box_before_idx ~= -1 and box_before_idx < #target_chain then
						target_key = target_chain[box_before_idx + 1]
					end
				end

				if target_key then
					block_lines[i] = line:gsub("/%*.-%*/", target_key .. ".receiver")
				else
					vim.notify("Could not resolve target for: " .. comment_content, vim.log.levels.WARN)
				end
			end
			break -- Assume only one forward_to line
		end
	end

	-- 4. Write the transformed block to the source buffer
	local new_type, new_label = block_lines[1]:match('^%s*([%w_%.]+)%s*"?([%w_%.]+)"?%s*{')
	local new_component_key = new_type .. "." .. new_label

	-- First, insert the new/updated block
	local insert_at_line = components[box_before.key].end_line
	local dedented_block_lines = vim.tbl_map(function(line)
		return line:gsub("^%s%s", "")
	end, block_lines)
	vim.api.nvim_buf_set_lines(source_bufnr, insert_at_line, insert_at_line, false, { "" })
	vim.api.nvim_buf_set_lines(
		source_bufnr,
		insert_at_line + 1,
		insert_at_line + 1,
		false,
		dedented_block_lines
	)

	-- Second, update the preceding block's `forward_to`
	local box_before_content = components[box_before.key].original_block_content
	local content_lines = vim.split(box_before_content, "\n")
	for i, line in ipairs(content_lines) do
		if line:match("%s*forward_to%s*=") then
			local old_forward_to_line_idx = components[box_before.key].line + i - 1
			local old_target_key = line:match("([%w_%.]+)%.receiver")
			if old_target_key then
				local new_forward_to_line =
					line:gsub(old_target_key .. ".receiver", new_component_key .. ".receiver")
				vim.api.nvim_buf_set_lines(
					source_bufnr,
					old_forward_to_line_idx - 1,
					old_forward_to_line_idx,
					false,
					{ new_forward_to_line }
				)
				break
			end
		end
	end

	-- 5. Clean up and refresh
	if vim.api.nvim_buf_is_valid(diagram_buf) then
		pcall(vim.api.nvim_buf_delete, diagram_buf, { force = true })
	end
	vim.notify("Synced block to source file.", vim.log.levels.INFO)
	require("features.outline.init").CreatePipelineDiagram(nil)
end

function M.diagram_filter()
	vim.ui.input({ prompt = "Filter by component label or type: " }, function(input)
		if input and input ~= "" then
			require("features.outline.init").CreatePipelineDiagram(input)
		end
	end)
end

function M.filter_by_cursor()
	local win_id = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win_id)
	local row = vim.api.nvim_win_get_cursor(win_id)[1]
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
	local label = line:match("%(([^%)]+)%)")
	if not label then
		label = line:match("([%w_%.]+)%s*$")
	end
	if label and label ~= "" then
		require("features.outline.init").CreatePipelineDiagram(label)
	end
end

function M.filter_current_component()
	local current_state = state.get_state()
	local _, box =
		diagram_utils.get_box_at_cursor(current_state.win_id, current_state.box_metadata, "vertical_list")
	if box and box.original_label then
		require("features.outline.init").CreatePipelineDiagram(box.original_label)
	end
end

function M.clear_filter()
	require("features.outline.init").CreatePipelineDiagram(nil)
end

return M
