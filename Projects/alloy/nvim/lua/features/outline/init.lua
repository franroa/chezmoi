local M = {}

local utils = require("core.utils")
local parser = require("core.parser")
local highlights = require("ui.highlights")
local state = require("features.common.state")
local ui = require("features.common.ui")
local outline_keymaps = require("features.outline.keymaps")
local actions = require("features.common.actions")
local tester = require("features.testing.utils.e2e_runner")

local ns_id_dim = utils.create_namespace("AlloyPipelineDim")
local ns_id_results = utils.create_namespace("AlloyPipelineResults")

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

function M.CreatePipelineDiagram(filter_word)
	tester.update_override_state()
	actions.show_override_icons_in_buffer()
	vim.notify(" Creating vertical diagram...")
	vim.schedule(function()
		local current_state = state.get_state()
		if current_state and current_state.win_id and vim.api.nvim_win_is_valid(current_state.win_id) then
			vim.api.nvim_win_close(current_state.win_id, true)
		end
		local source_bufnr = vim.api.nvim_get_current_buf()
		_setup_highlights()
		local components, all_chains_by_key, _ = parser.get_parsed_pipeline_data(source_bufnr)
		if not components or not all_chains_by_key then
			vim.notify("Could not analyze pipeline.", vim.log.levels.WARN)
			return
		end
		local filter_lower = nil
		local focus_key = nil
		local chains_to_render = all_chains_by_key
		if filter_word and filter_word ~= "" then
			if components[filter_word] then
				focus_key = filter_word
			else
				for key, comp_data in pairs(components) do
					if comp_data.label == filter_word then
						focus_key = key
						break
					end
				end
			end
			if focus_key then
				local filtered = {}
				for _, chain in ipairs(all_chains_by_key) do
					if vim.tbl_contains(chain, focus_key) then
						table.insert(filtered, chain)
					end
				end
				chains_to_render = filtered
				if components[focus_key] and components[focus_key].label then
					filter_lower = components[focus_key].label:lower()
				end
			else
				filter_lower = filter_word:lower()
				local filtered = {}
				for _, chain in ipairs(all_chains_by_key) do
					local matches = false
					for _, key in ipairs(chain) do
						if
							components[key]
							and (
								components[key].label:lower():find(filter_lower)
								or components[key].type:lower():find(filter_lower)
							)
						then
							matches = true
							break
						end
					end
					if matches then
						table.insert(filtered, chain)
					end
				end
				chains_to_render = filtered
			end
		end
		if #chains_to_render == 0 then
			vim.notify(
				filter_word and ("No pipelines match filter: '" .. filter_word .. "'") or "No pipelines found.",
				vim.log.levels.WARN
			)
			return
		end
		local output = { lines = {}, metadata = {} }
		if filter_lower then
			local display_filter = filter_word
			if focus_key and components[focus_key] then
				display_filter = components[focus_key].type .. ' "' .. components[focus_key].label .. '"'
			end
			local filter_content = " " .. display_filter
			table.insert(output.lines, "╭─ " .. filter_content .. " ─╮")
		else
			table.insert(output.lines, " [No Filter] ")
		end
		table.insert(output.lines, "")
		for i, chain in ipairs(chains_to_render) do
			if i > 1 then
				table.insert(output.lines, "")
			end
			table.insert(output.lines, string.format("--- Pipeline Branch %d ---", i))
			for _, key in ipairs(chain) do
				local comp = components[key]
				if comp then
					local is_match = filter_lower
						and (comp.label:lower():find(filter_lower) or comp.type:lower():find(filter_lower))
					local line_prefix = is_match and "▶" or " "
					local process_name = comp.type:match("%.([^.]+)$") or comp.type
					local icon = process_icons[process_name] or process_icons.default
					local children = comp.forward_to or {}
					local parents = comp.receives_from or {}
					local is_overridden = utils.overridden_components[comp.type .. "-" .. comp.label]
					local type_text = comp.type .. (is_overridden and " 🧪" or "")
					local line_text = string.format("%s %s %s (%s)", line_prefix, icon, type_text, comp.label)
					local indicators = {}
					if #parents > 1 then
						table.insert(indicators, " merging")
					end
					if #children > 1 then
						table.insert(indicators, " forking")
					end
					if #indicators > 0 then
						line_text = line_text .. " " .. table.concat(indicators, " ")
					end
					table.insert(output.lines, line_text)
					local meta = {
						key = key,
						line_in_diagram = #output.lines,
						source_line = comp.line,
						original_type = comp.type,
						original_label = comp.label,
						content = comp.content,
						icon = icon,
						is_filter_match = is_match,
						is_overridden = is_overridden,
						original_block_content = comp.original_block_content,
					}
					local margin = string.rep(" ", 2)
					local prefix = (is_match and "▶" or " ") .. " " .. icon .. " "
					meta.icon_col = vim.fn.strdisplaywidth(margin .. prefix) - vim.fn.strdisplaywidth(icon)
					meta.start_col = vim.fn.strdisplaywidth(margin)
					meta.end_col = vim.fn.strdisplaywidth(margin .. line_text)
					table.insert(output.metadata, meta)
				end
			end
		end
		local margin_str = string.rep(" ", 2)
		for i, line in ipairs(output.lines) do
			output.lines[i] = margin_str .. line
		end
		local max_width = 0
		for _, line in ipairs(output.lines) do
			max_width = math.max(max_width, vim.fn.strwidth(line))
		end
		local unpadded_filter_line = output.lines[1]
		local padding = max_width - vim.fn.strwidth(unpadded_filter_line)
		if padding > 0 then
			local pad_left = math.floor(padding / 2)
			local pad_right = padding - pad_left
			output.lines[1] = string.rep(" ", pad_left) .. unpadded_filter_line .. string.rep(" ", pad_right)
		end
		local win_width = math.min(max_width + 4, 100)
		local buf = vim.api.nvim_create_buf(false, true)
		vim.bo[buf].filetype = "alloy_vertical_diagram"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, output.lines)
		vim.cmd("rightbelow vsplit")
		local win_id = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_config(win_id, { title = "Vertical Pipeline", title_pos = "center" })
		vim.api.nvim_win_set_buf(win_id, buf)
		vim.api.nvim_win_set_width(win_id, win_width)
		vim.wo[win_id].cursorline = true
		vim.wo[win_id].number = false
		vim.wo[win_id].relativenumber = false
		vim.wo[win_id].signcolumn = "no"
		vim.wo[win_id].list = false
		vim.wo[win_id].spell = false
		vim.defer_fn(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			local line_to_meta = {}
			for _, meta in ipairs(output.metadata) do
				line_to_meta[meta.line_in_diagram] = meta
			end
			for i, line in ipairs(output.lines) do
				if i == 1 then
					local hl_group = filter_lower and "DiagramBoxFilter" or "DiagramBoxFilterInactive"
					vim.api.nvim_buf_add_highlight(buf, -1, hl_group, i - 1, 0, -1)
				elseif line:match("^%s*---") then
					vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxStageHeader", i - 1, 0, -1)
				elseif line_to_meta[i] then
					local meta = line_to_meta[i]
					local comp = components[meta.key]
					if comp then
						local offset = vim.fn.strwidth("▶ ") + vim.fn.strwidth(margin_str)
						local icon_bytes = #meta.icon
						vim.api.nvim_buf_add_highlight(
							buf,
							-1,
							"DiagramBox" .. (comp.color or "Storm"),
							i - 1,
							offset,
							offset + icon_bytes
						)
						vim.api.nvim_buf_add_highlight(
							buf,
							-1,
							"DiagramBoxComponentBaseText",
							i - 1,
							offset + icon_bytes + 1,
							-1
						)
						local type_s, type_e = line:find(comp.type, offset + icon_bytes + 2, true)
						if type_s then
							vim.api.nvim_buf_add_highlight(
								buf,
								-1,
								"DiagramBoxComponentTypeBold",
								i - 1,
								type_s - 1,
								type_e
							)
						end
						local label_s, label_e =
							line:find("(" .. comp.label .. ")", (type_e or (offset + icon_bytes)) + 1, true)
						if label_s then
							vim.api.nvim_buf_add_highlight(
								buf,
								-1,
								"DiagramBoxComponentLabelDim",
								i - 1,
								label_s - 1,
								label_e
							)
						end
						local merge_s, merge_e = line:find(" merging", 1, true)
						if merge_s then
							vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxBranchIcon", i - 1, merge_s - 1, merge_e)
						end
						local fork_s, fork_e = line:find(" forking", 1, true)
						if fork_s then
							vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxBranchIcon", i - 1, fork_s - 1, fork_e)
						end
					end
				end
			end
		end, 50)
		state.set_state({
			win_id = win_id,
			buf = buf,
			box_metadata = output.metadata,
			source_bufnr = source_bufnr,
			type = "vertical_list",
			popup_win_id = nil,
			help_popup_win_id = nil,
			pipelines = chains_to_render,
			components = components,
			nav_mode = "pipeline",
			focused_pipeline_index = nil,
		})
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(win_id),
			once = true,
			callback = function()
				_on_diagram_win_closed(win_id)
			end,
		})
		vim.api.nvim_create_autocmd("WinLeave", {
			buffer = buf,
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
		local follow_timer_diagram = nil
		local function debounced_follow_from_diagram()
			if follow_timer_diagram then
				follow_timer_diagram:close()
			end
			follow_timer_diagram = vim.loop.new_timer()
			follow_timer_diagram:start(50, 0, function()
				vim.schedule(require("features.common.actions").FollowFromDiagram)
			end)
		end
		vim.api.nvim_create_autocmd("CursorMoved", { buffer = buf, callback = debounced_follow_from_diagram })
		outline_keymaps.setup_keymaps()
		if focus_key then
			local target_meta = nil
			for _, m in ipairs(output.metadata) do
				if m.key == focus_key then
					target_meta = m
					break
				end
			end
			if target_meta then
				vim.api.nvim_win_set_cursor(win_id, { target_meta.line_in_diagram, 0 })
				vim.cmd("normal! zz")
				local source_win = vim.fn.bufwinid(source_bufnr)
				if source_win ~= -1 then
					local orig_scrolloff = vim.api.nvim_win_get_option(source_win, "scrolloff")
					vim.api.nvim_win_set_option(source_win, "scrolloff", 0)
					vim.api.nvim_win_set_cursor(source_win, { target_meta.source_line, 0 })
					vim.fn.win_execute(source_win, "normal! zt")
					vim.api.nvim_win_set_option(source_win, "scrolloff", orig_scrolloff)
				end
			end
		else
			require("features.common.actions").FollowComponentInDiagram()
		end
	end)
end

function _on_diagram_win_closed(win_id)
	ui.close_component_popup()
	ui.close_help_popup()
	local current_state = state.get_state()
	if current_state and current_state.win_id == win_id then
		if current_state.source_bufnr and vim.api.nvim_buf_is_valid(current_state.source_bufnr) then
			vim.api.nvim_buf_clear_namespace(current_state.source_bufnr, ns_id_dim, 0, -1)
		end
		if current_state.buf and vim.api.nvim_buf_is_valid(current_state.buf) then
			vim.api.nvim_buf_clear_namespace(current_state.buf, ns_id_results, 0, -1)
		end
		state.reset_state()
		utils.last_summary_data = nil
	end
end

function M.setup() end

return M
