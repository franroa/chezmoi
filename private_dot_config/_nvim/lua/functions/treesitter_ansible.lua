local M = {}

-- Debug function to print node structure
function M.debug_node_structure()
  local parsers = require("nvim-treesitter.parsers")
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local parser = parsers.get_parser(bufnr, "yaml")
  if not parser then
    vim.notify("Could not get YAML parser", vim.log.levels.ERROR)
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local node = root:descendant_for_range(row, col, row, col)

  if not node then
    vim.notify("No node at cursor", vim.log.levels.WARN)
    return
  end

  -- Print node hierarchy
  local current = node
  local level = 0
  while current and level < 10 do
    local indent = string.rep("  ", level)
    local node_text = vim.treesitter.get_node_text(current, bufnr)
    -- Truncate long text for readability
    if #node_text > 50 then
      node_text = node_text:sub(1, 47) .. "..."
    end
    -- Replace newlines for cleaner output
    node_text = node_text:gsub("\n", "\\n")
    vim.notify(string.format("%s%s: '%s'", indent, current:type(), node_text), vim.log.levels.INFO)
    current = current:parent()
    level = level + 1
  end
end

-- Function to find ansible inventory host name at cursor position
function M.find_and_pick_ansible_host()
  local parsers = require("nvim-treesitter.parsers")

  -- Ensure we have a YAML parser
  if not parsers.has_parser("yaml") then
    vim.notify("YAML TreeSitter parser not available", vim.log.levels.ERROR)
    return
  end

  -- Get the current buffer and cursor position
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2] -- Convert to 0-based indexing

  -- Get the syntax tree
  local parser = parsers.get_parser(bufnr, "yaml")
  if not parser then
    vim.notify("Could not get YAML parser for current buffer", vim.log.levels.ERROR)
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  -- Find the node at cursor position
  local node = root:descendant_for_range(row, col, row, col)
  if not node then
    vim.notify("No node found at cursor position", vim.log.levels.WARN)
    return
  end

  -- Traverse up the tree to find a host definition
  local current_node = node
  local hostname = nil

  while current_node do
    local node_type = current_node:type()

    -- Look for block_mapping_pair nodes that could represent hosts
    if node_type == "block_mapping_pair" then
      -- Get the key (first child should be the key)
      local key_node = current_node:child(0)
      if key_node then
        local key_text = vim.treesitter.get_node_text(key_node, bufnr)

        -- Clean the key text (remove quotes, colons, etc.)
        key_text = key_text:gsub("^[\"']?([^\"':]*).*", "%1")

        -- Check if this looks like a hostname (not ansible keywords)
        if
          key_text
          and key_text ~= ""
          and key_text ~= "all"
          and key_text ~= "hosts"
          and key_text ~= "ansible_host"
          and key_text ~= "ansible_user"
          and key_text ~= "app_list"
          and key_text ~= "customer"
          and key_text ~= "client_distinctive"
          and key_text ~= "env"
          and key_text ~= "ansible_ssh_common_args"
          and not key_text:match("^ansible_")
          and not key_text:match("^#")
        then -- Ignore comments
          -- Check if we're in the right context by looking for 'hosts' in the ancestry
          local found_hosts_ancestor = false
          local check_node = current_node:parent()
          local depth = 0

          -- Look up the tree for the 'hosts' section
          while check_node and depth < 10 do
            if check_node:type() == "block_mapping_pair" then
              local check_key_node = check_node:child(0)
              if check_key_node then
                local check_key_text = vim.treesitter.get_node_text(check_key_node, bufnr)
                if check_key_text == "hosts" then
                  found_hosts_ancestor = true
                  break
                end
              end
            end
            check_node = check_node:parent()
            depth = depth + 1
          end

          if found_hosts_ancestor then
            hostname = key_text
            break
          end
        end
      end
    end

    current_node = current_node:parent()
  end

  if hostname then
    return hostname
  else
    vim.notify("No hostname found at cursor position", vim.log.levels.WARN)
  end
end

-- Optional: Create a keymap for easy access
-- vim.keymap.set('n', '<leader>ah', M.find_and_pick_ansible_host, { desc = 'Pick Ansible host at cursor' })

return M
