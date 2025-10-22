local ns = vim.api.nvim_create_namespace("alloy_validation")

local function show_pipeline_flow()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand("%:p")

  if vim.fn.fnamemodify(file, ":e") ~= "alloy" then
    print("Not an Alloy file")
    return
  end

  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local buffer_content = table.concat(buffer_lines, "\n")

  -- Remove comments for parsing
  local clean_content = buffer_content:gsub("/%*.-%*/", function(comment)
    return comment:gsub("[^\n]", " ")
  end)
  clean_content = clean_content:gsub("//[^\n]*", function(comment)
    return comment:gsub(".", " ")
  end)

  local components = {}
  local declares = {}
  local arguments = {}

  -- Parse declare blocks first
  local declare_pattern = 'declare%s+"([%w_%.]+)"%s*{'
  local search_offset = 1

  while true do
    local s, e, declare_name = clean_content:find(declare_pattern, search_offset)
    if not s then
      break
    end

    local line_num = 1 + select(2, clean_content:sub(1, s):gsub("\n", ""))

    -- Find the matching closing brace for declare
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
      local declare_content = clean_content:sub(e + 1, content_end - 1)
      declares[declare_name] = {
        name = declare_name,
        content = declare_content,
        line = line_num,
        arguments = {},
        components = {},
      }

      -- Parse arguments within declare
      for arg_name in declare_content:gmatch('argument%s+"([%w_%.]+)"%s*{') do
        table.insert(declares[declare_name].arguments, arg_name)
        arguments[arg_name] = { declare = declare_name, type = "argument" }
      end

      search_offset = content_end + 1
    else
      search_offset = e + 1
    end
  end

  -- Parse all components (both inside and outside declares)
  search_offset = 1
  local component_pattern = '([%w_%.]+)%s+"([%w_%.]+)"%s*{'

  while true do
    local s, e, c_type, c_label = clean_content:find(component_pattern, search_offset)
    if not s then
      break
    end

    -- Skip if this is a declare block or argument
    if c_type == "declare" or c_type == "argument" then
      search_offset = e + 1
      goto continue
    end

    local line_num = 1 + select(2, clean_content:sub(1, s):gsub("\n", ""))

    -- Find the matching closing brace
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
      local key = c_type .. "." .. c_label

      -- Determine which declare this component belongs to
      local parent_declare = nil
      for declare_name, declare_data in pairs(declares) do
        local declare_start = string.find(clean_content, 'declare%s+"' .. declare_name .. '"%s*{')
        local declare_end_pos = declare_start
        if declare_start then
          local brace_count = 1
          for i = declare_start + 1, #clean_content do
            local char = clean_content:sub(i, i)
            if char == "{" then
              brace_count = brace_count + 1
            elseif char == "}" then
              brace_count = brace_count - 1
              if brace_count == 0 then
                declare_end_pos = i
                break
              end
            end
          end
        end

        if declare_start and s > declare_start and s < declare_end_pos then
          parent_declare = declare_name
          table.insert(declares[declare_name].components, key)
          break
        end
      end

      components[key] = {
        type = c_type,
        label = c_label,
        content = c_content,
        line = line_num,
        forward_to = {},
        argument_refs = {},
        parent_declare = parent_declare,
      }

      -- Parse argument references
      for arg_ref in c_content:gmatch("argument%.([%w_%.]+)%.value") do
        table.insert(components[key].argument_refs, arg_ref)
      end

      search_offset = content_end + 1
    else
      search_offset = e + 1
    end

    ::continue::
  end

  -- Parse forward_to relationships
  for key, comp in pairs(components) do
    local forward_content = comp.content:match("forward_to%s*=%s*%[([^]]+)%]")
    if forward_content then
      forward_content = forward_content:gsub("//[^\n]*", ""):gsub("\n", " ")
      for target in forward_content:gmatch("([%w_%.]+%.receiver)") do
        local target_key = target:match("([%w_%.]+)%.receiver")
        if target_key and components[target_key] then
          table.insert(comp.forward_to, target_key)
        end
      end

      -- Also look for argument references in forward_to
      for arg_ref in forward_content:gmatch("argument%.([%w_%.]+)%.value") do
        table.insert(comp.argument_refs, arg_ref)
      end
    end
  end

  -- Build pipeline visualization
  local output = { "=== Alloy Pipeline Flow ===" }
  table.insert(output, "")

  -- Show declare blocks and their internal pipelines
  for declare_name, declare_data in pairs(declares) do
    table.insert(output, string.format('📦 declare "%s" [line:%d]', declare_name, declare_data.line))

    -- Show arguments
    if #declare_data.arguments > 0 then
      table.insert(output, "  ┌─ 📋 Arguments:")
      for i, arg in ipairs(declare_data.arguments) do
        local is_last_arg = i == #declare_data.arguments
        local arg_prefix = is_last_arg and "  └─" or "  ├─"
        table.insert(output, string.format("%s   • %s", arg_prefix, arg))
      end
      table.insert(output, "")
    end

    -- Show components within this declare
    if #declare_data.components > 0 then
      table.insert(output, "  ┌─ 🔄 Internal Pipeline:")

      -- Find pipeline chains within this declare
      local declare_components = {}
      for _, comp_key in ipairs(declare_data.components) do
        declare_components[comp_key] = components[comp_key]
      end

      -- Find start nodes within declare
      local is_target = {}
      for _, comp in pairs(declare_components) do
        for _, target in ipairs(comp.forward_to) do
          if declare_components[target] then -- Only count targets within same declare
            is_target[target] = true
          end
        end
      end

      local start_nodes = {}
      for key, _ in pairs(declare_components) do
        if not is_target[key] then
          table.insert(start_nodes, key)
        end
      end

      -- Build pipeline chains in execution order
      local pipeline_chains = {}
      local visited = {}

      -- Build complete chains from start to end
      for _, start_key in ipairs(start_nodes) do
        if not visited[start_key] then
          local function build_chain(key, current_chain)
            if visited[key] or not declare_components[key] then
              return
            end

            local new_chain = {}
            for _, k in ipairs(current_chain) do
              table.insert(new_chain, k)
            end
            table.insert(new_chain, key)
            visited[key] = true

            local comp = declare_components[key]
            if #comp.forward_to == 0 then
              -- End of chain, store it
              table.insert(pipeline_chains, new_chain)
            else
              -- Continue building chain
              for _, target_key in ipairs(comp.forward_to) do
                if declare_components[target_key] then
                  build_chain(target_key, new_chain)
                end
              end
            end
          end

          build_chain(start_key, {})
        end
      end

      -- Display chains in order
      for chain_idx, chain in ipairs(pipeline_chains) do
        local chain_prefix = #pipeline_chains > 1 and string.format("Chain %d: ", chain_idx) or ""

        for step_idx, key in ipairs(chain) do
          local comp = declare_components[key]
          local indent = "  "
          local connector = step_idx == 1 and "└─" or "  "
          local arrow = step_idx == 1 and "" or "    ↓"

          if step_idx > 1 then
            table.insert(output, "  " .. arrow)
          end

          -- Show component with argument usage
          local step_num = step_idx > 1 and string.format("[%d] ", step_idx) or "[1] "
          local comp_info =
            string.format("%s%s%s%s.%s [line:%d]", indent, connector, step_num, comp.type, comp.label, comp.line)

          if #comp.argument_refs > 0 then
            comp_info = comp_info .. " 📎(" .. table.concat(comp.argument_refs, ", ") .. ")"
          end

          table.insert(output, comp_info)

          -- Show stages if it's a process component
          if comp.type:match("%.process$") then
            local stages = {}
            for stage in comp.content:gmatch("stage%.([%w_]+)") do
              table.insert(stages, stage)
            end
            if #stages > 0 then
              table.insert(output, "      └─ 🔧 stages: " .. table.concat(stages, " → "))
            end
          end
        end

        if chain_idx < #pipeline_chains then
          table.insert(output, "")
        end
      end
    end

    table.insert(output, "")
  end

  -- Show components outside of declares
  local orphan_components = {}
  for key, comp in pairs(components) do
    if not comp.parent_declare then
      table.insert(orphan_components, key)
    end
  end

  if #orphan_components > 0 then
    table.insert(output, "🌐 Global Components:")
    for _, key in ipairs(orphan_components) do
      local comp = components[key]
      table.insert(output, string.format("  └─ %s.%s [line:%d]", comp.type, comp.label, comp.line))
    end
    table.insert(output, "")
  end

  -- Add summary with hierarchy call info
  local total_declares = vim.tbl_count(declares)
  local total_components = vim.tbl_count(components)
  local total_arguments = 0
  for _, declare_data in pairs(declares) do
    total_arguments = total_arguments + #declare_data.arguments
  end

  table.insert(output, "📊 Summary:")
  table.insert(output, string.format("  • %d declare block(s)", total_declares))
  table.insert(output, string.format("  • %d component(s)", total_components))
  table.insert(output, string.format("  • %d argument(s)", total_arguments))

  -- Show call hierarchy (providers)
  table.insert(output, "")
  table.insert(output, "🔗 Call Hierarchy (Providers):")
  for declare_name, declare_data in pairs(declares) do
    if #declare_data.arguments > 0 then
      table.insert(output, string.format("  📦 %s provides:", declare_name))
      for _, arg in ipairs(declare_data.arguments) do
        local usage_count = 0
        local used_by = {}

        for comp_key, comp in pairs(components) do
          if comp.parent_declare == declare_name then
            for _, arg_ref in ipairs(comp.argument_refs) do
              if arg_ref == arg then
                usage_count = usage_count + 1
                table.insert(used_by, comp.label)
                break
              end
            end
          end
        end

        if usage_count > 0 then
          table.insert(output, string.format("    └─ %s → used by: %s", arg, table.concat(used_by, ", ")))
        else
          table.insert(output, string.format("    └─ %s (unused)", arg))
        end
      end
    end
  end

  -- Create a new buffer to display the result
  local result_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(result_bufnr, 0, -1, false, output)
  vim.bo[result_bufnr].filetype = "text"
  vim.bo[result_bufnr].buftype = "nofile"
  vim.bo[result_bufnr].swapfile = false

  -- Open in a split window
  vim.cmd("vsplit")
  local win_id = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win_id, result_bufnr)

  -- Set up keymaps for the result window
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win_id, true)
  end, { buffer = result_bufnr, silent = true })

  -- Add jump to line functionality
  vim.keymap.set("n", "<CR>", function()
    local cursor_line = vim.api.nvim_win_get_cursor(win_id)[1]
    local line_text = vim.api.nvim_buf_get_lines(result_bufnr, cursor_line - 1, cursor_line, false)[1]
    local line_num = line_text:match("%[line:(%d+)%]")

    if line_num then
      vim.api.nvim_win_close(win_id, true)
      vim.api.nvim_win_set_cursor(0, { tonumber(line_num), 0 })
      vim.cmd("normal! zz")
    end
  end, { buffer = result_bufnr, silent = true })
end

local function validate_alloy()
  local file = vim.fn.expand("%:p")
  local bufnr = vim.api.nvim_get_current_buf()

  if vim.fn.fnamemodify(file, ":e") ~= "alloy" then
    return
  end

  local dir = vim.fn.fnamemodify(file, ":h")
  local files = vim.fn.glob(dir .. "/*.alloy", false, true)
  if #files == 0 then
    return
  end

  -- Clear diagnostics for all open buffers in the directory
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_file = vim.api.nvim_buf_get_name(buf)
      if vim.fn.fnamemodify(buf_file, ":h") == dir and vim.fn.fnamemodify(buf_file, ":e") == "alloy" then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      end
    end
  end

  local has_errors = false
  local diagnostics_per_buf = {}

  local cmd = { "alloy", "validate", dir }

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local stdout_output = table.concat(data, "\n")
        if stdout_output:match("Error:") then
          has_errors = true
          vim.schedule(function()
            local all_errors = {}
            for line in stdout_output:gmatch("[^\r\n]+") do
              local filepath, l, c, msg = line:match("Error: ([^:]+):(%d+):(%d+): (.+)")
              if filepath and l and c and msg then
                if not filepath:match("^/") then
                  filepath = dir .. "/" .. filepath
                end
                table.insert(all_errors, string.format("%s:%s:%s: %s", filepath, l, c, msg))
                local bufnr = vim.fn.bufnr(filepath)
                if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
                  if not diagnostics_per_buf[bufnr] then
                    diagnostics_per_buf[bufnr] = {}
                  end
                  local line_num = tonumber(l) - 1
                  local col_num = tonumber(c) - 1

                  table.insert(diagnostics_per_buf[bufnr], {
                    bufnr = bufnr,
                    lnum = line_num,
                    col = col_num,
                    severity = vim.diagnostic.severity.ERROR,
                    message = msg,
                    source = "alloy",
                  })
                end
              end
            end

            for buf, diags in pairs(diagnostics_per_buf) do
              vim.diagnostic.set(ns, buf, diags)
            end
          end)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local stderr_output = table.concat(data, "\n")
        if stderr_output:match("Error:") then
          has_errors = true
          vim.schedule(function()
            local all_errors = {}
            for line in stderr_output:gmatch("[^\r\n]+") do
              local filepath, l, c, msg = line:match("Error: ([^:]+):(%d+):(%d+): (.+)")
              if filepath and l and c and msg then
                if not filepath:match("^/") then
                  filepath = dir .. "/" .. filepath
                end
                table.insert(all_errors, string.format("%s:%s:%s: %s", filepath, l, c, msg))
                local bufnr = vim.fn.bufnr(filepath)
                if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
                  if not diagnostics_per_buf[bufnr] then
                    diagnostics_per_buf[bufnr] = {}
                  end
                  local line_num = tonumber(l) - 1
                  local col_num = tonumber(c) - 1

                  table.insert(diagnostics_per_buf[bufnr], {
                    bufnr = bufnr,
                    lnum = line_num,
                    col = col_num,
                    severity = vim.diagnostic.severity.ERROR,
                    message = msg,
                    source = "alloy",
                  })
                end
              end
            end

            for buf, diags in pairs(diagnostics_per_buf) do
              vim.diagnostic.set(ns, buf, diags)
            end
          end)
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 and not has_errors then
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
              local buf_file = vim.api.nvim_buf_get_name(buf)
              if vim.fn.fnamemodify(buf_file, ":h") == dir and vim.fn.fnamemodify(buf_file, ":e") == "alloy" then
                vim.diagnostic.set(ns, buf, {})
              end
            end
          end
        end
      end)
    end,
  })
end

-- local function format_alloy()
--   local file = vim.fn.expand("%:p")
--   local bufnr = vim.api.nvim_get_current_buf()
--
--   if vim.fn.fnamemodify(file, ":e") ~= "alloy" then
--     return
--   end
--
--   -- Save cursor position
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--
--   local cmd = { "alloy", "fmt", file }
--
--   -- Run synchronously using vim.system
--   local result = vim.system(cmd, { text = true }):wait()
--
--   if result.code == 0 then
--     if result.stdout and result.stdout:match("%S") then
--       -- Replace buffer content with formatted version
--       local lines = vim.split(result.stdout, "\n")
--       -- Remove last empty line if it exists
--       if lines[#lines] == "" then
--         table.remove(lines)
--       end
--       vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
--       -- Restore cursor position
--       pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
--
--       -- Save the file
--       vim.cmd("write")
--     end
--   else
--     if result.stderr and result.stderr:match("%S") then
--       vim.notify("Alloy fmt error: " .. result.stderr, vim.log.levels.ERROR)
--     else
--       vim.notify("Alloy fmt failed with exit code: " .. result.code, vim.log.levels.ERROR)
--     end
--   end
-- end

return {
  -- format_alloy = format_alloy,
  validate_alloy = validate_alloy,
  show_pipeline_flow = show_pipeline_flow,
}
