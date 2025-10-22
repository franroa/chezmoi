-- lua/treesitter_autofold.lua (or integrate into your existing config)
-- Version with support for injected languages.

local M = {}

-- Stores the { start_line, end_line } of the last unfolded node for each buffer.
local last_unfolded_node_info = {}

--- Gets the innermost Tree-sitter node at the cursor, searching across all
--- injected language trees for the smallest possible node.
-- @return (userdata|nil) The Tree-sitter node, or nil if none found.
local function get_innermost_node_at_cursor()
  local buf_id = vim.api.nvim_get_current_buf()
  local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  cursor_line = cursor_line - 1 -- Convert to 0-indexed line

  local innermost_node = nil
  local smallest_size = -1

  -- Get the main parser for the buffer, which manages all language trees.
  local parser = vim.treesitter.get_parser(buf_id)
  if not parser then
    return nil
  end

  -- Correctly iterate over all trees (base and injected) using parser:trees().
  for _, tree in ipairs(parser:trees()) do
    local root = tree:root()
    -- Find the smallest node at the cursor position within this tree.
    local node_at_cursor = root:named_descendant_for_range(cursor_line, cursor_col, cursor_line, cursor_col)

    if node_at_cursor then
      local start_line, _, end_line, _ = node_at_cursor:range()
      local node_size = end_line - start_line

      -- If this is the first node we've found, or if it's smaller than the
      -- previous smallest, it becomes our new candidate for the innermost node.
      if smallest_size == -1 or node_size < smallest_size then
        smallest_size = node_size
        innermost_node = node_at_cursor
      end
    end
  end

  return innermost_node
end

--- Unfolds a specific fold based on its start line.
-- @param line (number) The 0-indexed start line of the fold.
local function unfold_at_line(line)
  -- Temporarily move the cursor to the fold's start line to open it.
  local current_cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { line + 1, current_cursor[2] })

  -- 'zO' opens all nested folds at the cursor line. 'zo' opens just one level.
  -- 'silent!' prevents errors if no fold is found.
  vim.cmd("silent! normal! zO")

  -- Restore the original cursor position.
  vim.api.nvim_win_set_cursor(0, current_cursor)
end

--- Collapses all folds in the current buffer.
local function collapse_all_folds()
  vim.cmd("silent! normal! zM")
end

--- Main callback for CursorMoved event.
local function handle_cursor_moved()
  local buf_id = vim.api.nvim_get_current_buf()

  -- Ensure we are in a targeted filetype.
  local filetype = vim.bo[buf_id].filetype
  if filetype ~= M.target_filetype then
    return
  end

  -- Use our new function to get the node, which may be from an injected language.
  local current_node = get_innermost_node_at_cursor()

  if current_node then
    local node_start_line, _, node_end_line, _ = current_node:range()
    local last_info = last_unfolded_node_info[buf_id]

    -- If we've moved to a new node, update the folds.
    if not last_info or last_info.start ~= node_start_line or last_info.end_line ~= node_end_line then
      collapse_all_folds()
      unfold_at_line(node_start_line)
      last_unfolded_node_info[buf_id] = { start = node_start_line, end_line = node_end_line }
    end
  else
    -- If no node is under the cursor (e.g., empty space), collapse everything.
    if last_unfolded_node_info[buf_id] then
      collapse_all_folds()
      last_unfolded_node_info[buf_id] = nil
    end
  end
end

--- Setup function to be called from your init.lua.
-- @param filetype_to_target (string) The filetype to activate autofolding for.
M.setup = function(filetype_to_target)
  M.target_filetype = filetype_to_target or "lua"

  local fold_group = vim.api.nvim_create_augroup("TreesitterDynamicFold", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = fold_group,
    pattern = "*", -- Apply to all buffers entering
    callback = function()
      local buf_id = vim.api.nvim_get_current_buf()
      if vim.bo[buf_id].filetype == M.target_filetype then
        -- Initially fold everything when entering a target buffer.
        vim.opt_local.foldenable = true
        vim.cmd("silent! normal! zM")
        last_unfolded_node_info[buf_id] = nil
      end
    end,
    desc = "Initial autofold on entering a target filetype buffer",
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = fold_group,
    pattern = "*", -- We check the filetype inside the callback
    callback = handle_cursor_moved,
    desc = "Dynamic Treesitter fold/unfold on cursor move",
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    group = fold_group,
    pattern = "*",
    callback = function(args)
      -- Clean up state when leaving or wiping out any buffer.
      last_unfolded_node_info[args.buf] = nil
    end,
    desc = "Clean up dynamic fold state on leaving buffer",
  })
end

return M
