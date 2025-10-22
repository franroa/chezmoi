local M = {}

local parser = require("core.parser")

local function get_sorted_components_and_current_index()
	local current_buf = vim.api.nvim_get_current_buf()
	local components, _, _ = parser.get_parsed_pipeline_data(current_buf)
	if not components or vim.tbl_isempty(components) then
		return nil, nil, nil
	end

	local sorted_components = {}
	for _, comp in pairs(components) do
		table.insert(sorted_components, comp)
	end
	table.sort(sorted_components, function(a, b)
		return a.line < b.line
	end)

	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local current_idx = 0
	for i, comp in ipairs(sorted_components) do
		if cursor_line >= comp.line and cursor_line <= comp.end_line then
			current_idx = i
			break
		end
	end

	return sorted_components, current_idx, cursor_line
end

function M.jump_to_next_block()
	local sorted_components, current_idx = get_sorted_components_and_current_index()
	if not sorted_components then
		return
	end

	local next_idx = (current_idx % #sorted_components) + 1
	local next_comp = sorted_components[next_idx]
	if next_comp then
		vim.api.nvim_win_set_cursor(0, { next_comp.line, 0 })
		vim.cmd("normal! zz")
	end
end

function M.jump_to_previous_block()
	local sorted_components, current_idx = get_sorted_components_and_current_index()
	if not sorted_components then
		return
	end

	local prev_idx
	if current_idx == 0 then
		-- If cursor is not in any block, jump to the last one
		prev_idx = #sorted_components
	else
		prev_idx = ((current_idx - 2 + #sorted_components) % #sorted_components) + 1
	end

	local prev_comp = sorted_components[prev_idx]
	if prev_comp then
		vim.api.nvim_win_set_cursor(0, { prev_comp.line, 0 })
		vim.cmd("normal! zz")
	end
end

return M