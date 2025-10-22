--- Alloy configuration parser with intelligent caching.
---
--- This module provides efficient parsing of Alloy configuration files with
--- structural caching that only invalidates when component relationships change.
--- The parser has been refactored from a monolithic 200+ line function into
--- focused, testable helper functions.
---
--- @version 2.0.0
--- @module core.parser

local M = {}

local utils = require("core.utils")

--- Cache table storing parsed data associated with specific file states.
--- Cache keys are generated from structural content to ensure invalidation
--- only occurs when component definitions or relationships change.
local cache = {}

--- Generates a unique key representing the structural state of the Alloy pipeline.
-- The key is designed to change only when a component is added/removed, or when
-- the connections (`forward_to`, `targets`) between components are modified.
-- It ignores cosmetic changes like comments or whitespace.
-- @param bufnr (number) The buffer number.
-- @param buffer_lines (table) A table of strings representing the lines in the buffer.
-- @return (string) The generated cache key.
local function generate_cache_key(bufnr, buffer_lines)
	local buffer_content = table.concat(buffer_lines, "\n")

	-- 1. Create a clean version of the content by stripping out comments.
	-- This ensures that adding or changing comments won't invalidate the cache.
	local clean_content = buffer_content:gsub("/%*.-%*/", function(comment)
		return comment:gsub("[^\n]", " ")
	end)
	clean_content = clean_content:gsub("//[^\n]*", function(comment)
		return comment:gsub(".", " ")
	end)

	local structural_parts = {}

	-- 2. Iterate over each line to find "structurally significant" parts.
	for line in clean_content:gmatch("[^\n]+") do
		local trimmed_line = line:match("^%s*(.-)%s*$")

		-- 3. A line is significant if it defines a component or a connection.
		if
			trimmed_line:match('^[%w_%.]+%s+"[%w_%.]+"%s*{') -- Component declaration
			or trimmed_line:match("^forward_to%s*=") -- Forwarding rule
			or trimmed_line:match("^targets%s*=") -- Target definition
		then
			-- 4. To make the key canonical, remove all whitespace from the significant line.
			-- This makes the cache insensitive to formatting changes.
			-- NOTE: We wrap gsub in parentheses to discard its second return value (the count of substitutions).
			table.insert(structural_parts, (trimmed_line:gsub("%s+", "")))
		end
	end

	-- 5. Sort the parts to ensure the order of components in the file doesn't affect the key.
	table.sort(structural_parts)

	-- 6. The final key combines the buffer ID with the concatenated structural parts.
	return bufnr .. ":" .. table.concat(structural_parts, ";")
end

--- Retrieves data from the cache if it's recent and valid.
-- @param cache_key (string) The key to look up in the cache.
-- @return (table|nil, table|nil, table|nil) The cached data or nil if not found/expired.
local function get_from_cache(cache_key)
	local cached = cache[cache_key]
	-- Cache is valid for 30 seconds.
	if cached and (vim.loop.now() - cached.timestamp) < 30000 then
		utils.notify_debug("Cache hit: structure unchanged.")
		return cached.components, cached.all_chains_by_key, cached.start_nodes
	end
	return nil
end

--- Stores the parsed pipeline data in the cache.
-- @param cache_key (string) The key to store the data under.
-- @param components (table) The parsed components map.
-- @param all_chains_by_key (table) The calculated pipeline chains.
-- @param start_nodes (table) The identified start nodes of the pipeline.
local function store_in_cache(cache_key, components, all_chains_by_key, start_nodes)
	cache[cache_key] = {
		components = components,
		all_chains_by_key = all_chains_by_key,
		start_nodes = start_nodes,
		timestamp = vim.loop.now(),
	}

	-- Cleanup old cache entries to prevent memory leaks.
	local current_time = vim.loop.now()
	for key, entry in pairs(cache) do
		-- Remove entries older than 1 minute.
		if (current_time - entry.timestamp) > 60000 then
			cache[key] = nil
		end
	end
end

--- Clean buffer content by removing comments while preserving line structure.
-- @param buffer_lines (table) A table of strings representing the lines in the buffer.
-- @return (string) The cleaned buffer content.
local function clean_buffer_content(buffer_lines)
	local buffer_content = table.concat(buffer_lines, "\n")

	-- Remove block comments
	local clean_content = buffer_content:gsub("/%*.-%*/", function(comment)
		return comment:gsub("[^\n]", " ")
	end)

	-- Remove line comments
	clean_content = clean_content:gsub("//[^\n]*", function(comment)
		return comment:gsub(".", " ")
	end)

	return clean_content
end

--- Parse components from the cleaned buffer content.
-- @param bufnr (number) The buffer number.
-- @param clean_content (string) The cleaned buffer content.
-- @return (table, table) components, forward_targets
local function parse_components(bufnr, clean_content)
	local components, forward_targets = {}, {}
	local search_offset = 1
	local pattern = '([%w_%.]+)%s+"([%w_%.]+)"%s*{'

	while true do
		local s, e, c_type, c_label = clean_content:find(pattern, search_offset)
		if not s then
			break
		end

		local line_num = 1 + select(2, clean_content:sub(1, s):gsub("\n", ""))
		local brace_level, content_end = 1, -1

		for i = e + 1, #clean_content do
			local char = clean_content:sub(i, i)
			if char == "{" then
				brace_level = brace_level + 1
			elseif char == "}" then
				brace_level = brace_level - 1
				if brace_level == 0 then
					content_end = i
					break
				end
			end
		end

		if content_end ~= -1 then
			local c_content = clean_content:sub(e + 1, content_end - 1)
			local end_line = 1 + select(2, clean_content:sub(1, content_end):gsub("\n", ""))
			local original_block_content =
				table.concat(vim.api.nvim_buf_get_lines(bufnr, line_num - 1, end_line, false), "\n")

			components[c_type .. "." .. c_label] = {
				type = c_type,
				label = c_label,
				content = c_content,
				line = line_num,
				end_line = end_line,
				original_block_content = original_block_content,
			}

			search_offset = content_end + 1
		else
			search_offset = e + 1
		end
	end

	return components, forward_targets
end

--- Parse relationships between components (forward_to and targets).
-- @param components (table) The components map.
-- @param forward_targets (table) The forward targets map.
local function parse_component_relationships(components, forward_targets)
	local receives_from = {}

	for key, comp in pairs(components) do
		local forward_content = comp.content:match("forward_to%s*=%s*%[([^]]+)%]")
		if forward_content then
			if not comp.forward_to then
				comp.forward_to = {}
			end
			forward_content = forward_content:gsub("//[^\n]*", ""):gsub("\n", " ")
			for target in forward_content:gmatch("([%w_%.]+%.receiver)") do
				local target_key = target:match("([%w_%.]+)%.receiver")
				if target_key then
					table.insert(comp.forward_to, target_key)
					forward_targets[target_key] = true
					if not receives_from[target_key] then
						receives_from[target_key] = {}
					end
					table.insert(receives_from[target_key], key)
				end
			end
		end

		for provider_key in comp.content:gmatch("targets%s*=%s*([%w_%.]+)%.targets") do
			if components[provider_key] then
				if not components[provider_key].forward_to then
					components[provider_key].forward_to = {}
				end
				table.insert(components[provider_key].forward_to, key)
				forward_targets[key] = true
				if not receives_from[key] then
					receives_from[key] = {}
				end
				table.insert(receives_from[key], provider_key)
			end
		end
	end

	for key, sources in pairs(receives_from) do
		if components[key] then
			components[key].receives_from = sources
		end
	end
end

--- Find start nodes in the pipeline.
-- @param components (table) The components map.
-- @param forward_targets (table) The forward targets map.
-- @return (table) The start nodes.
local function find_start_nodes(components, forward_targets)
	local start_nodes = {}
	for key, _ in pairs(components) do
		if not forward_targets[key] and not key:match("write") and not key:match("export") then
			table.insert(start_nodes, key)
		end
	end
	return start_nodes
end

--- Build pipeline chains from start nodes.
-- @param components (table) The components map.
-- @param start_nodes (table) The start nodes.
-- @return (table) The pipeline chains.
local function build_pipeline_chains(components, start_nodes)
	local all_chains_by_key = {}
	for _, start_key in ipairs(start_nodes) do
		local stack = { { start_key } }
		while #stack > 0 do
			local current_path_keys = table.remove(stack)
			local last_key_in_path = current_path_keys[#current_path_keys]
			local node = components[last_key_in_path]
			if node and node.forward_to and #node.forward_to > 0 then
				for _, next_key in ipairs(node.forward_to) do
					if not vim.tbl_contains(current_path_keys, next_key) then
						local new_path = vim.deepcopy(current_path_keys)
						table.insert(new_path, next_key)
						table.insert(stack, new_path)
					end
				end
			else
				table.insert(all_chains_by_key, current_path_keys)
			end
		end
	end
	return all_chains_by_key
end

--- Apply color coding to components based on pipeline chains.
-- @param components (table) The components map.
-- @param all_chains_by_key (table) The pipeline chains.
local function apply_component_colors(components, all_chains_by_key)
	local highlights = require("ui.highlights")
	if highlights and highlights.tokyonight_futuristic_hls then
		local color_index = 1
		for _, chain_keys in ipairs(all_chains_by_key) do
			local color_name = highlights.tokyonight_futuristic_hls.key_order[color_index]
			for _, key in ipairs(chain_keys) do
				if components[key] and not components[key].color then
					components[key].color = color_name
				end
			end
			color_index = (color_index % #highlights.tokyonight_futuristic_hls.key_order) + 1
		end
	end
end

--- Function to get he key of an alloy component
-- @return (string) component name
function M.get_key_under_cursor()
	local source_bufnr = vim.api.nvim_get_current_buf()
	local components, _, _ = M.get_parsed_pipeline_data(source_bufnr)
	local focus_key = nil
	if components then
		local cursor_line = vim.api.nvim_get_current_buf()
		for key, comp_data in pairs(components) do
			if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
				focus_key = key
				break
			end
		end
	end
	return focus_key
end

--- Main function to parse an Alloy file, using a cache to avoid redundant work.
-- @param bufnr (number) The buffer number of the file to parse.
-- @return (table, table, table) components, all_chains_by_key, start_nodes
function M.get_parsed_pipeline_data(bufnr)
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		utils.notify_debug("Invalid buffer provided to parser")
		return nil, nil, nil
	end

	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	if not buffer_lines or #buffer_lines == 0 then
		utils.notify_debug("Buffer is empty or could not read lines")
		return nil, nil, nil
	end

	-- Generate the key based on the buffer's current structural content.
	local cache_key = generate_cache_key(bufnr, buffer_lines)

	-- Try to fetch from cache first.
	local components, all_chains_by_key, start_nodes = get_from_cache(cache_key)
	if components then
		return components, all_chains_by_key, start_nodes
	end

	utils.notify_debug_chunks({
		{ "Cache miss: Re-parsing pipeline.", "ERROR" },
	})

	local clean_content = clean_buffer_content(buffer_lines)
	local components, forward_targets = parse_components(bufnr, clean_content)

	utils.notify_debug("Processing " .. #buffer_lines .. " lines of content")

	if vim.tbl_isempty(components) then
		utils.notify_debug("Exiting: No components were found after parsing.")
		return nil, nil, nil
	end

	utils.notify_debug("Found " .. vim.tbl_count(components) .. " components")

	parse_component_relationships(components, forward_targets)

	local start_nodes = find_start_nodes(components, forward_targets)

	if #start_nodes == 0 then
		utils.notify_debug("Exiting: No start nodes were found in the pipeline.")
		return {}, {}, {}
	end

	local all_chains_by_key = build_pipeline_chains(components, start_nodes)
	apply_component_colors(components, all_chains_by_key)

	utils.notify_debug("Parsing complete. About to store in cache and notify.")
	-- Store the newly parsed data in the cache.
	store_in_cache(cache_key, components, all_chains_by_key, start_nodes)

	utils.notify_debug_chunks({
		{ "Cache recreated for pipeline for buffer ", "Normal" },
		{ vim.fs.basename(vim.api.nvim_buf_get_name(bufnr)), "@keyword" },
		{ ".", "Normal" },
	})
	return components, all_chains_by_key, start_nodes
end

return M
