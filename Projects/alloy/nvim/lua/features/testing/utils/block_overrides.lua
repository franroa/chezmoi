local utils = require("core.utils")

local M = {}

function M.get_override_content(component_key, override_dir_name)
	local override_file_path = vim.fn.getcwd() .. "/" .. override_dir_name .. "/" .. component_key .. "/localtest.alloy"
	if vim.fn.filereadable(override_file_path) == 1 then
		local content_lines = vim.fn.readfile(override_file_path)
		return table.concat(content_lines, "\n")
	end
	return nil
end

function M.load_block_overrides(override_dir_name)
	utils.notify_debug("Scanning for block overrides...")
	local overrides = {}
	local root_dir = vim.fn.getcwd()
	local override_path = root_dir .. "/" .. override_dir_name

	if vim.fn.isdirectory(override_path) == 0 then
		utils.notify_debug("No " .. override_dir_name .. " directory found.")
		return overrides
	end

	utils.overridden_components = {}

	local items = vim.fn.readdir(override_path)
	local count = 0
	for _, item_name in ipairs(items) do
		local full_path = override_path .. "/" .. item_name
		local override_file_path = full_path .. "/localtest.alloy"

		if vim.fn.isdirectory(full_path) == 1 and vim.fn.filereadable(override_file_path) == 1 then
			local content_lines = vim.fn.readfile(override_file_path)
			if content_lines and #content_lines > 0 then
				local override_key = item_name
				local override_content = table.concat(content_lines, " ")
				overrides[override_key] = override_content
				utils.overridden_components[override_key] = true
				count = count + 1
			end
		end
	end
	utils.notify_debug("Found " .. count .. " override(s).")
	return overrides
end

function M.update_override_state(override_dir_name)
	utils.notify_debug("Updating override state...")
	local root_dir = vim.fn.getcwd()
	local override_path = root_dir .. "/" .. override_dir_name

	utils.overridden_components = {}

	if vim.fn.isdirectory(override_path) == 0 then
		return
	end

	local items = vim.fn.readdir(override_path)
	for _, item_name in ipairs(items) do
		local full_path = override_path .. "/" .. item_name
		local override_file_path = full_path .. "/localtest.alloy"
		if vim.fn.isdirectory(full_path) == 1 and vim.fn.filereadable(override_file_path) == 1 then
			utils.overridden_components[item_name] = true
		end
	end
end

function M.apply_overrides_to_buffer(source_bufnr, block_overrides, placeholders, log_window)
	local original_lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
	local overrides_applied = {}
	local replacement_plan = {}
	local i = 1
	while i <= #original_lines do
		local line = original_lines[i]
		for key, new_content in pairs(block_overrides) do
			if not overrides_applied[key] then
				local type, label = key:match("^(.*)-([^-]+)$")
				if type and type ~= "" and label and label ~= "" then
					local start_pattern = "^%s*" .. vim.pesc(type) .. '%s*"' .. vim.pesc(label) .. '"'
					if line:match(start_pattern) then
						local block_start_idx = i
						local block_end_idx = -1
						local brace_level = 0
						local found_first_brace = false
						for j = block_start_idx, #original_lines do
							local current_line = original_lines[j]
							for char_idx = 1, #current_line do
								local char = current_line:sub(char_idx, char_idx)
								if char == "{" then
									brace_level = brace_level + 1
									found_first_brace = true
								elseif char == "}" then
									brace_level = brace_level - 1
								end
							end
							if found_first_brace and brace_level == 0 then
								block_end_idx = j
								break
							end
						end
						if block_end_idx ~= -1 then
							replacement_plan[block_start_idx] = {
								start_idx = block_start_idx,
								end_idx = block_end_idx,
								content = new_content,
							}
							overrides_applied[key] = true
							i = block_end_idx
							break
						end
					end
				end
			end
		end
		i = i + 1
	end

	local final_lines_for_display = {}
	local final_lines_for_file = {}
	i = 1
	while i <= #original_lines do
		if replacement_plan[i] then
			local plan = replacement_plan[i]
			local block_diff_display = {}
			local original_block_lines = {}
			for k = plan.start_idx, plan.end_idx do
				table.insert(original_block_lines, original_lines[k])
			end
			local new_block_lines = vim.split(plan.content, "\n", { trimempty = false })
			local original_set = {}
			for _, line in ipairs(original_block_lines) do
				original_set[vim.trim(line)] = true
			end
			local new_set = {}
			for _, line in ipairs(new_block_lines) do
				new_set[vim.trim(line)] = true
			end
			local removed_lines_for_display = {}
			for _, line in ipairs(original_block_lines) do
				if not new_set[vim.trim(line)] then
					table.insert(removed_lines_for_display, { content = line, type = "removed" })
				end
			end
			local removed_lines_inserted = false
			for _, line in ipairs(new_block_lines) do
				table.insert(final_lines_for_file, line)
				if not original_set[vim.trim(line)] then
					table.insert(block_diff_display, { content = line, type = "added" })
					if not removed_lines_inserted then
						vim.list_extend(block_diff_display, removed_lines_for_display)
						removed_lines_inserted = true
					end
				else
					table.insert(block_diff_display, { content = line, type = "unchanged" })
				end
			end
			vim.list_extend(final_lines_for_display, block_diff_display)
			i = plan.end_idx + 1
		else
			table.insert(final_lines_for_display, { content = original_lines[i], type = "unchanged" })
			table.insert(final_lines_for_file, original_lines[i])
			i = i + 1
		end
	end

	for key, _ in pairs(block_overrides) do
		if not overrides_applied[key] then
			log_window.log_message(
				string.format(
					"[ERROR] WARNING: Override for '%s' was found, but a matching block was not found in the source to replace.",
					key
				),
				"ErrorMsg"
			)
		end
	end

	for _, line_obj in ipairs(final_lines_for_display) do
		for p_key, p_value in pairs(placeholders) do
			line_obj.content = line_obj.content:gsub("{{" .. p_key .. "}}", p_value)
		end
	end
	for idx, line in ipairs(final_lines_for_file) do
		for p_key, p_value in pairs(placeholders) do
			final_lines_for_file[idx] = line:gsub("{{" .. p_key .. "}}", p_value)
		end
	end

	return final_lines_for_file, final_lines_for_display
end

return M
