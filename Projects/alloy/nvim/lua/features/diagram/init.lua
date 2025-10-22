local M = {}

local diagram_utils = require("ui.diagram_utils")
local highlights = require("ui.highlights")
local ui = require("features.common.ui")
local diagram_keymaps = require("features.diagram.keymaps")
local tester = require("features.testing.utils.e2e_runner")
local utils = require("core.utils")
local parser = require("core.parser")
local state = require("features.common.state")
local actions = require("features.common.actions")
local diagram_actions = require("features.diagram.actions")

local ns_id_results = utils.create_namespace("AlloyPipelineResults")
local ns_id_pipeline_numbers = utils.create_namespace("AlloyPipelineNumbers")

local ns_id_dim = utils.create_namespace("AlloyPipelineDim")

local futuristic_process_icons = {
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
local process_icons = futuristic_process_icons

local function _setup_highlights()
	highlights.setup_highlights()
end

function M.get_box_at_cursor(win_id, metadata, diagram_type)
	return diagram_utils.get_box_at_cursor(win_id, metadata, diagram_type)
end
function M.GetPipelineSteps(source_bufnr)
	local components, all_chains_by_key, _ = parser.get_parsed_pipeline_data(source_bufnr)
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

function M.CreatePipelineDiagram(opts)
	-- moved verbatim from original main.lua CreatePipelineDiagram
	opts = opts or {}
	vim.notify(" Creating pipeline diagram...")
	vim.schedule(function()
		tester.update_override_state()
		actions.show_override_icons_in_buffer()
		local focus_key = opts.focus_key
		local source_bufnr = vim.api.nvim_get_current_buf()
		local current_state = state.get_state()
		if current_state and current_state.win_id and vim.api.nvim_win_is_valid(current_state.win_id) then
			vim.api.nvim_win_close(current_state.win_id, true)
		end
		state.reset_state()
		local components, all_chains_by_key, _ = parser.get_parsed_pipeline_data(source_bufnr)
		if not components or not all_chains_by_key then
			vim.notify("Could not analyze pipeline.", vim.log.levels.WARN)
			return
		end
		local groups = M.GetPipelineSteps(source_bufnr)
		if groups == nil or vim.tbl_isempty(groups) then
			vim.notify("No pipelines found to visualize.", vim.log.levels.WARN)
			return
		end
		_setup_highlights()
		local arrow_chars =
			{ h = "─", v = "│", bl = "└", br = "┘", tr = "┐", arrow = "►", up = "▲", down = "▼" }
		local arrow = " " .. string.rep(arrow_chars.h, 2) .. arrow_chars.arrow .. " "
		local final_content, box_metadata, drawn_node_coords = {}, {}, {}
		local sorted_group_keys = {}
		for k in pairs(groups) do
			table.insert(sorted_group_keys, k)
		end
		table.sort(sorted_group_keys)
		-- building horizontal diagram content (same logic as original)
		for group_idx, key in ipairs(sorted_group_keys) do
			local group = groups[key]
			local max_text_widths = {}
			local icon_part_width = 4
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
				local margin_str = string.rep(" ", 2)
				table.insert(top_parts, margin_str)
				table.insert(type_parts, margin_str)
				table.insert(name_parts, margin_str)
				table.insert(bottom_parts, margin_str)
				local current_byte_col = vim.fn.strwidth(margin_str)
				local row_start_line = #final_content + 1
				if i > 1 then
					local parent_box_width = max_screen_widths[1]
					local gap_width = vim.fn.strwidth(arrow)
					local indent_width = parent_box_width + gap_width
					local center_col_of_parent = math.floor(parent_box_width / 2)
					local line1_content = string.rep(" ", center_col_of_parent) .. arrow_chars.v
					local h_line_len = math.max(0, indent_width - center_col_of_parent - 1 - 2)
					local line2_content = string.rep(" ", center_col_of_parent)
						.. arrow_chars.bl
						.. string.rep(arrow_chars.h, h_line_len)
						.. arrow_chars.arrow
						.. " "
					table.insert(
						top_parts,
						line1_content .. string.rep(" ", indent_width - vim.fn.strwidth(line1_content))
					)
					table.insert(type_parts, line2_content)
					table.insert(name_parts, string.rep(" ", indent_width))
					table.insert(bottom_parts, string.rep(" ", indent_width))
					current_byte_col = current_byte_col + indent_width
				end
				for j = (i == 1 and 1 or 2), #chain_data do
					local box_data = chain_data[j]
					local box_key = box_data.key
					if drawn_node_coords[box_key] then
						local target_coords = drawn_node_coords[box_key]
						local distance = math.max(2, target_coords.start_col - current_byte_col)
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
						current_byte_col = current_byte_col + distance
						break
					end
					local process_name = box_data.original_type:match("%.([^.]+)$") or box_data.original_type
					local icon = process_icons[process_name] or process_icons.default
					local text_part_width = max_text_widths[j]
					local is_overridden =
						utils.overridden_components[box_data.original_type .. "-" .. box_data.original_label]
					local centered_type = utils.center_text(box_data.original_type, text_part_width)
					local centered_label = utils.center_text(box_data.original_label, text_part_width)
					local centered_icon = utils.center_text(icon, icon_part_width - 2)
					local icon_col_2_content = is_overridden and utils.center_text("🧪", icon_part_width)
						or string.rep(" ", icon_part_width)
					local text_padding = string.rep("─", text_part_width + 2)
					local icon_padding = string.rep("─", icon_part_width)
					local t_part = "┌" .. icon_padding .. "┬" .. text_padding .. "┐"
					local l1_part = "│ " .. centered_icon .. " │ " .. centered_type .. " │"
					local l2_part = "│" .. icon_col_2_content .. "│ " .. centered_label .. " │"
					local b_part = "└" .. icon_padding .. "┴" .. text_padding .. "┘"
					table.insert(top_parts, t_part)
					table.insert(type_parts, l1_part)
					table.insert(name_parts, l2_part)
					table.insert(bottom_parts, b_part)
					local box_byte_length = vim.fn.strwidth(l1_part)
					if box_byte_length <= 0 then
						box_byte_length = 10
					end
					local icon_line = row_start_line + 1
					local icon_col = current_byte_col + 3
					table.insert(box_metadata, {
						key = box_data.key,
						label = box_data.original_label,
						line_in_diagram = row_start_line,
						start_col = current_byte_col,
						end_col = current_byte_col + box_byte_length - 1,
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
					if j < #chain_data then
						local next_box_key = chain_data[j + 1].key
						if not drawn_node_coords[next_box_key] then
							local arrow_space = string.rep(" ", vim.fn.strwidth(arrow))
							table.insert(top_parts, arrow_space)
							table.insert(type_parts, arrow)
							table.insert(name_parts, arrow_space)
							table.insert(bottom_parts, arrow_space)
							current_byte_col = current_byte_col + vim.fn.strwidth(arrow)
						end
					end
				end
				table.insert(final_content, table.concat(top_parts))
				table.insert(final_content, table.concat(type_parts))
				table.insert(final_content, table.concat(name_parts))
				table.insert(final_content, table.concat(bottom_parts))
			end
			if group_idx < #sorted_group_keys then
				table.insert(final_content, "")
			end
		end
		if #final_content == 0 then
			vim.notify("No pipelines found to visualize.", vim.log.levels.WARN)
			return
		end
		local diagram_height = #final_content
		local container_height = diagram_height + 2
		local container_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[container_buf].buftype = "nofile"
		local container_win_id = ui.create_top_split_window(container_buf, container_height)
		vim.wo[container_win_id].winhighlight = "Normal:Comment"

		local diagram_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[diagram_buf].filetype = "alloy_horizontal_diagram"
		vim.api.nvim_buf_set_lines(diagram_buf, 0, -1, false, final_content)
		local diagram_width = 0
		for _, line in ipairs(final_content) do
			diagram_width = math.max(diagram_width, vim.fn.strwidth(line))
		end
		local float_win_id = ui.create_styled_popup(
			diagram_buf,
			"Pipeline Diagram",
			diagram_width,
			diagram_height,
			{ relative = "win", win = container_win_id }
		)
		state.set_state({
			win_id = float_win_id,
			container_win_id = container_win_id,
			original_container_height = container_height,
			buf = diagram_buf,
			box_metadata = box_metadata,
			source_bufnr = source_bufnr,
			type = "horizontal",
			popup_win_id = nil,
			help_popup_win_id = nil,
			pipelines = all_chains_by_key,
			components = components,
			nav_mode = "pipeline",
			focused_pipeline_index = nil,
			total_content_width = diagram_width,
		})
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(float_win_id),
			once = true,
			callback = function()
				if vim.api.nvim_win_is_valid(container_win_id) then
					vim.api.nvim_win_close(container_win_id, true)
				end
			end,
		})
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(container_win_id),
			once = true,
			callback = function()
				if vim.api.nvim_win_is_valid(float_win_id) then
					vim.api.nvim_win_close(float_win_id, true)
				end
			end,
		})
		vim.defer_fn(function()
			if not vim.api.nvim_buf_is_valid(diagram_buf) then
				return
			end
			local line_to_color_hl = {}
			for _, box in ipairs(box_metadata) do
				local hl = "DiagramBox" .. (box.color or "Storm")
				for i = 0, 3 do
					line_to_color_hl[box.line_in_diagram + i] = hl
				end
			end
			for i, line_content in ipairs(final_content) do
				local line_idx = i - 1
				local connector_hl = line_to_color_hl[i] or "DiagramBoxTreeConnector"
				local offset = 1
				while true do
					local arrow_start, arrow_end = line_content:find(arrow, offset, true)
					if not arrow_start then
						break
					end
					vim.api.nvim_buf_add_highlight(
						diagram_buf,
						-1,
						"DiagramArrow",
						line_idx,
						arrow_start - 1,
						arrow_end
					)
					offset = arrow_end + 1
				end
				offset = 1
				while offset <= #line_content do
					local s, e = string.find(
						line_content,
						"[└┘┐┌│─┬┴═▲▼" .. arrow_chars.arrow .. "]",
						offset
					)
					if not s then
						break
					end
					vim.api.nvim_buf_add_highlight(diagram_buf, -1, connector_hl, line_idx, s - 1, e)
					offset = e + 1
				end
			end
		end, 50)
		vim.api.nvim_create_autocmd("WinLeave", {
			buffer = diagram_buf,
			callback = function()
				local current_state = state.get_state()
				if
					current_state
					and current_state.source_bufnr
					and vim.api.nvim_buf_is_valid(current_state.source_bufnr)
				then
					vim.api.nvim_buf_clear_namespace(current_state.source_bufnr, ns_id_dim, 0, -1)
				end
			end,
		})
		vim.api.nvim_create_autocmd("CursorMoved", {
			buffer = diagram_buf,
			callback = function()
				local current_state = state.get_state()
				if not current_state then
					return
				end
				local _, box = require("ui.diagram_utils").get_box_at_cursor(
					diagram_buf,
					current_state.box_metadata,
					current_state.type
				)
				local key = box and box.key or nil
				if current_state.last_focused_component == key then
					return
				end
				state.update_state("last_focused_component", key)
				vim.schedule(function()
					require("features.diagram").FollowFromDiagram()
				end)
			end,
		})
		diagram_keymaps.setup_keymaps()
		if focus_key and state.get_state() then
			vim.schedule(function()
				local current_state = state.get_state()
				if not current_state then
					return
				end
				local target_pipeline_index = nil
				for i, pipeline in ipairs(current_state.pipelines) do
					if vim.tbl_contains(pipeline, focus_key) then
						target_pipeline_index = i
						break
					end
				end
				local target_box = nil
				for _, box in ipairs(current_state.box_metadata) do
					if box.key == focus_key then
						target_box = box
						break
					end
				end
				if target_pipeline_index and target_box then
					state.update_state("nav_mode", "component")
					state.update_state("focused_pipeline_index", target_pipeline_index)
					local start_node_key = current_state.pipelines[target_pipeline_index][1]
					local keys_in_group = {}
					for _, chain in ipairs(current_state.pipelines) do
						if #chain > 0 and chain[1] == start_node_key then
							for _, key in ipairs(chain) do
								keys_in_group[key] = true
							end
						end
					end
					local min_line, max_line = 9999, 0
					for _, box in ipairs(current_state.box_metadata) do
						if keys_in_group[box.key] then
							min_line = math.min(min_line, box.line_in_diagram)
							max_line = math.max(max_line, box.line_in_diagram)
						end
					end
					if min_line <= max_line then
						local content_height = (max_line - min_line) + 4
						local new_container_height = content_height + 2
						if
							current_state.container_win_id and vim.api.nvim_win_is_valid(current_state.container_win_id)
						then
							vim.api.nvim_win_set_height(current_state.container_win_id, new_container_height)
							vim.api.nvim_win_set_config(current_state.win_id, { height = content_height })
						end
					end
					diagram_utils.jump_to_component(current_state, focus_key)
					local source_win_id = vim.fn.bufwinid(current_state.source_bufnr)
					if source_win_id ~= -1 then
						local original_scrolloff = vim.api.nvim_win_get_option(source_win_id, "scrolloff")
						vim.api.nvim_win_set_option(source_win_id, "scrolloff", 0)
						vim.api.nvim_win_set_cursor(source_win_id, { target_box.source_line, 0 })
						vim.fn.win_execute(source_win_id, "normal! zt")
						vim.api.nvim_win_set_option(source_win_id, "scrolloff", original_scrolloff)
					end
				end
			end)
		else
			require("features.common.actions").FollowComponentInDiagram()
		end
	end)
end

function M.update_diagram_with_results(summary_data)
	local current_state = state.get_state()
	if not current_state or not current_state.win_id or not vim.api.nvim_win_is_valid(current_state.win_id) then
		return
	end
	local buf = current_state.buf
	vim.api.nvim_buf_clear_namespace(buf, ns_id_results, 0, -1)
	local result_hl = summary_data.test_passed and "DiagramBoxSuccess" or "DiagramBoxFailure"
	local result_text
	if summary_data.test_passed then
		result_text = " ✅ Passed"
	else
		local parts = {}
		if #summary_data.missing_logs > 0 then
			table.insert(parts, #summary_data.missing_logs .. " missing")
		end
		if #summary_data.unexpected_logs > 0 then
			table.insert(parts, #summary_data.unexpected_logs .. " unexpected")
		end
		result_text = " ❌ (" .. table.concat(parts, ", ") .. ")"
	end
	for _, box in ipairs(current_state.box_metadata) do
		if box.original_type:match("write") then
			for i = 0, 3 do
				vim.api.nvim_buf_add_highlight(buf, ns_id_results, result_hl, box.line_in_diagram - 1 + i, 0, -1)
			end
			vim.api.nvim_buf_set_extmark(
				buf,
				ns_id_results,
				box.line_in_diagram,
				-1,
				{ virt_text = { { result_text, result_hl } }, virt_text_pos = "eol" }
			)
		end
	end
end

function M.setup()
	local keymaps = require("features.diagram.keymaps")
	-- ensure default keymaps are applied; setup_default_keymaps is idempotent
	keymaps.setup_keymaps()
	-- utils.visualizer_module = M

	-- 				break
	-- 			end
	-- 		end
	-- 	end
	-- 	if current_state.last_source_component == current_key then
	-- 		return
	-- 	end
	-- 	state.update_state("last_source_component", current_key)
	-- 	if follow_timer then
	-- 		follow_timer:close()
	-- 	end
	-- 	follow_timer = vim.loop.new_timer()
	-- 	follow_timer:start(150, 0, function()
	-- 		vim.schedule(M.FollowComponentInDiagram)
	local group = vim.api.nvim_create_augroup("AlloyPipelineKeymaps", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "alloy",
		group = group,
		callback = function(args)
			vim.api.nvim_create_autocmd("User", {
				pattern = "AlloyVerticalDiagramOpened",
				callback = function() end,
			})
			vim.api.nvim_create_autocmd("BufEnter", {
				buffer = args.buf,
				callback = function()
					vim.defer_fn(actions.show_override_icons_in_buffer, 100)
				end,
			})
		end,
	})
end

function M.ClearPipelineNumbers()
	vim.api.nvim_buf_clear_namespace(0, ns_id_pipeline_numbers, 0, -1)
	vim.notify("Cleared pipeline icons.", vim.log.levels.INFO)
end

function M.FoldUnrelatedPipelines()
	local current_buf = vim.api.nvim_get_current_buf()
	local components, all_chains_by_key, _ = parser.get_parsed_pipeline_data(current_buf)
	if not components or not all_chains_by_key then
		vim.notify("Could not analyze pipelines to fold.", vim.log.levels.WARN)
		return
	end
	local original_cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_line = original_cursor[1]
	local current_component_key = nil
	for key, comp_data in pairs(components) do
		if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
			current_component_key = key
			break
		end
	end
	if not current_component_key then
		vim.notify("Cursor is not inside a component block.", vim.log.levels.INFO)
		return
	end
	local relevant_component_keys = {}
	if all_chains_by_key then
		for _, chain in ipairs(all_chains_by_key) do
			if vim.tbl_contains(chain, current_component_key) then
				for _, key_in_chain in ipairs(chain) do
					relevant_component_keys[key_in_chain] = true
				end
			end
		end
	end
	vim.cmd("setlocal foldmethod=manual")
	vim.cmd("normal! zR")
	local folded_count = 0
	for key, comp_data in pairs(components) do
		if not relevant_component_keys[key] then
			vim.api.nvim_command(string.format("%d,%dfold", comp_data.line, comp_data.end_line))
			folded_count = folded_count + 1
		end
	end
	vim.api.nvim_win_set_cursor(0, original_cursor)
	if folded_count > 0 then
		vim.notify(string.format("Folded %d unrelated component(s).", folded_count), vim.log.levels.INFO)
	end
end

function M.FocusPipeline()
	diagram_actions.ShowPipelineNumbers()
	M.FoldUnrelatedPipelines()
end
return M
