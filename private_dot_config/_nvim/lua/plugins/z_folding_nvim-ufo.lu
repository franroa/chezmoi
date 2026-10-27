-- lua
return {
  "kevinhwang91/nvim-ufo",
  dependencies = {
    "kevinhwang91/promise-async",
  },
  event = "BufRead",
  init = function()
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldcolumn = "1"
  end,
  config = function()
    local ufo = require("ufo")

    ---
    -- 🎨 Color Palette & ⚙️ Pipeline Analysis
    ---
    local pipeline_colors = {
      "MiniIconsOrange",
      "MiniIconsBlue",
      "MiniIconsGreen",
      "MiniIconsPurple",
      "MiniIconsCyan",
      "MiniIconsRed",
    }
    local pipeline_cache = {}

    -- This is your internal helper function, it remains unchanged.
    local function _get_parsed_pipeline_data(bufnr)
      local buffer_content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
      local clean_content = buffer_content:gsub("/%*.-%*/", function(comment)
        return comment:gsub("[^\n]", " ")
      end)
      clean_content = clean_content:gsub("//[^\n]*", function(comment)
        return comment:gsub(".", " ")
      end)
      local components = {}
      local forward_targets = {}
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
            components[c_type .. "." .. c_label] =
              { type = c_type, label = c_label, content = c_content, line = line_num, end_offset = content_end }
            search_offset = content_end + 1
          else
            search_offset = e + 1
          end
        end
      end
      if vim.tbl_isempty(components) then
        return nil, nil
      end
      for key, comp in pairs(components) do
        local forward_content = comp.content:match("forward_to%s*=%s*%[([^]]+)%]")
        if forward_content then
          if not comp.forward_to then
            comp.forward_to = {}
          end
          for target in forward_content:gmatch("([%w_%.]+)%.receiver") do
            table.insert(comp.forward_to, target)
            forward_targets[target] = true
          end
        end
        for provider_key in comp.content:gmatch("targets%s*=%s*([%w_%.]+)%.targets") do
          if components[provider_key] then
            if not components[provider_key].forward_to then
              components[provider_key].forward_to = {}
            end
            table.insert(components[provider_key].forward_to, key)
            forward_targets[key] = true
          end
        end
      end
      local start_nodes = {}
      for key, _ in pairs(components) do
        if not forward_targets[key] and not key:match("write") and not key:match("export") then
          table.insert(start_nodes, key)
        end
      end
      if #start_nodes == 0 then
        return nil, nil
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
      return components, all_chains_by_key
    end

    -- This function also detects ramifications (unchanged).
    local function compute_pipeline_data(bufnr)
      local components, all_chains = _get_parsed_pipeline_data(bufnr)
      if not components or not all_chains then
        return {}
      end

      local line_to_data = {}
      local already_numbered = {}
      local chains_by_start_node = {}

      for _, chain in ipairs(all_chains) do
        if #chain > 0 then
          local start_node_key = chain[1]
          if not chains_by_start_node[start_node_key] then
            chains_by_start_node[start_node_key] = {}
          end
          table.insert(chains_by_start_node[start_node_key], chain)
        end
      end

      local sorted_start_nodes = {}
      for key in pairs(chains_by_start_node) do
        table.insert(sorted_start_nodes, key)
      end
      table.sort(sorted_start_nodes)

      for pipeline_idx, start_key in ipairs(sorted_start_nodes) do
        local color = pipeline_colors[(pipeline_idx - 1) % #pipeline_colors + 1]
        local chains_in_pipeline = chains_by_start_node[start_key]

        for _, chain in ipairs(chains_in_pipeline) do
          for i, key in ipairs(chain) do
            if not already_numbered[key] then
              local comp_data = components[key]
              if comp_data then
                local is_ramification = false
                local branch_count = 0
                if comp_data.forward_to and #comp_data.forward_to > 1 then
                  is_ramification = true
                  branch_count = #comp_data.forward_to
                end

                line_to_data[comp_data.line] = {
                  step = i,
                  color = color,
                  is_ramification = is_ramification,
                  branch_count = branch_count,
                }
                already_numbered[key] = true
              end
            end
          end
        end
      end
      return line_to_data
    end

    -- Gets the cached data, or computes it if the cache is empty (unchanged).
    local function get_cached_pipeline_data(bufnr)
      if not pipeline_cache[bufnr] then
        pipeline_cache[bufnr] = compute_pipeline_data(bufnr)
      end
      return pipeline_cache[bufnr]
    end

    -- Autocommands to clear the cache (unchanged).
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = vim.api.nvim_create_augroup("UfoAlloyCache", { clear = true }),
      pattern = "*.alloy",
      callback = function(args)
        pipeline_cache[args.buf] = nil
      end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = vim.api.nvim_create_augroup("UfoAlloyCache", { clear = false }),
      pattern = "*",
      callback = function(args)
        pipeline_cache[args.buf] = nil
      end,
    })

    ---
    -- ✨ UFO Configuration ✨
    ---
    _G.ufo_custom_handler_active = true -- Global toggle

    -- The main handler for fold text.
    local main_fold_handler = function(virt_text, lnum, end_lnum, width, truncate)
      if _G.ufo_custom_handler_active and vim.bo.filetype == "alloy" then
        local bufnr = vim.api.nvim_get_current_buf()
        local pipeline_data = get_cached_pipeline_data(bufnr)
        local component_info = pipeline_data[lnum]

        table.insert(virt_text, { "}", "@punctuation.bracket" })

        if component_info then
          -- ✨ MODIFIED: Build the icon string additively.
          -- Start with the base icon and step number for all components.
          local icon_text = "  " .. component_info.step

          -- If it's a ramification, append the branch icon and count.
          if component_info.is_ramification then
            icon_text = icon_text .. "  " .. component_info.branch_count
          end

          -- Add a final space for padding and create the text chunk.
          local prefix_chunk = { icon_text .. " ", component_info.color }

          table.insert(virt_text, 1, prefix_chunk)

          -- Manually truncate the combined result to fit the window width.
          local new_virt_text, current_width = {}, 0
          for _, chunk in ipairs(virt_text) do
            local chunk_text, chunk_width = chunk[1], vim.fn.strwidth(chunk[1])
            if current_width + chunk_width <= width then
              table.insert(new_virt_text, chunk)
              current_width = current_width + chunk_width
            else
              local remaining_width = width - current_width
              if remaining_width > 0 then
                table.insert(new_virt_text, { truncate(chunk_text, remaining_width), chunk[2] })
              end
              break
            end
          end
          return new_virt_text
        end
      end
      return virt_text
    end

    -- Command to toggle the feature on/off (unchanged).
    vim.api.nvim_create_user_command("UfoToggleCustomFoldText", function()
      _G.ufo_custom_handler_active = not _G.ufo_custom_handler_active
      local status = _G.ufo_custom_handler_active and "ENABLED" or "DISABLED"
      vim.notify("UFO: Custom Alloy fold text " .. status, vim.log.levels.INFO)
      local view = vim.fn.winsaveview()
      ufo.closeAllFolds()
      ufo.openAllFolds()
      vim.fn.winrestview(view)
    end, { desc = "Toggle custom fold text handler for nvim-ufo (Alloy only)" })

    -- Final UFO setup call (unchanged).
    ufo.setup({
      provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
      end,
      fold_virt_text_handler = main_fold_handler,
    })
  end,
}
