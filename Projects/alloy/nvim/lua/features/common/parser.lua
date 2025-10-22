local M = {}

local utils = require("core.utils")

local cache = {
  bufnr = nil,
  components = nil,
  all_chains_by_key = nil,
  start_nodes = nil,
  structural_hash = nil,
}

function M.get_parsed_pipeline_data(bufnr)
  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local component_keys = {}
  for _, line in ipairs(buffer_lines) do
    for type, label in line:gmatch('^%s*([%w_%.]+)%s+"([%w_%.]+)"%s*{') do
      table.insert(component_keys, type .. "." .. label)
    end
  end
  table.sort(component_keys)
  local structural_hash = table.concat(component_keys, ";")

  if cache.bufnr == bufnr and cache.structural_hash == structural_hash and cache.components then
    utils.notify_debug("Cache hit: structure unchanged.")
    return cache.components, cache.all_chains_by_key, cache.start_nodes
  end

  utils.notify_debug("Cache miss: structure changed. Re-parsing pipeline.")
  local buffer_content = table.concat(buffer_lines, "\n")
  local clean_content = buffer_content:gsub([[/\*.-%*/]], function(comment)
    return comment:gsub("[^\n]", " ")
  end)
  clean_content = clean_content:gsub([[/\/[^\n]*]], function(comment)
    return comment:gsub(".", " ")
  end)

  local components, forward_targets = {}, {}
  do
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
  end

  if vim.tbl_isempty(components) then
    return nil, nil, nil
  end

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

  local start_nodes = {}
  for key, _ in pairs(components) do
    if not forward_targets[key] and not key:match("write") and not key:match("export") then
      table.insert(start_nodes, key)
    end
  end

  if #start_nodes == 0 then
    return nil, nil, nil
  end

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

  local highlights = require("ui.highlights")
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

  cache.bufnr = bufnr
  cache.components = components
  cache.all_chains_by_key = all_chains_by_key
  cache.start_nodes = start_nodes
  cache.structural_hash = structural_hash

  return components, all_chains_by_key, start_nodes
end

return M
