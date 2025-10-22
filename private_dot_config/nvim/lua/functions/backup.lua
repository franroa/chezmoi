-- lua/treesitter_autofold.lua (or integrate into your existing config)

local M = {}

local last_unfolded_node_info = {}
local function get_current_ts_node()
  return vim.treesitter.get_node()
end

-- Function to unfold a specific fold based on its start line
local function unfold_at_line(line)
  -- The 'zo' command opens one fold at the cursor.
  -- We need to temporarily move the cursor to the fold's start line.
  local current_cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { line + 1, current_cursor[2] }) -- +1 because Neovim lines are 1-indexed

  -- 'silent!' to prevent error messages if no fold is found
  vim.cmd("silent! normal! zO")

  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, current_cursor)
end

-- Function to collapse all folds in the current buffer
local function collapse_all_folds()
  -- Using 'zM' (fold all) is efficient.
  -- Setting foldlevel=0 locally works but 'zM' might be more immediate.
  vim.cmd("silent! normal! zM")
  -- Or: vim.opt_local.foldlevel = 0
end

-- Main callback for CursorMoved
local function handle_cursor_moved()
  local buf_id = vim.api.nvim_get_current_buf()

  -- Only apply this logic to our special filetype
  local filetype = vim.bo[buf_id].filetype
  -- Replace 'lua' with your specific filetype, or add multiple:
  -- if filetype ~= 'lua' and filetype ~= 'your_other_filetype' then return end
  if filetype ~= M.target_filetype then
    return
  end

  local current_node = get_current_ts_node()

  if current_node then
    local node_start_line, _, node_end_line, _ = current_node:range()
    local last_info = last_unfolded_node_info[buf_id]

    -- Check if we are still within the same node that was previously unfolded,
    -- or if we are on a new node and it should be unfolded.
    if not last_info or last_info[1] ~= node_start_line or last_info[2] ~= node_end_line then
      -- Collapse everything first to ensure previous unfolds are reset
      collapse_all_folds()

      -- Unfold the current node
      unfold_at_line(node_start_line)

      -- Store the current node's range
      last_unfolded_node_info[buf_id] = { node_start_line, node_end_line }
    end
  else
    -- If no Tree-sitter node is under the cursor (e.g., empty space, comment)
    -- or if we moved outside the last tracked node, collapse all folds.
    -- (This happens if `get_current_ts_node` returns nil)
    local last_info = last_unfolded_node_info[buf_id]
    if last_info then
      collapse_all_folds()
      last_unfolded_node_info[buf_id] = nil
    end
  end
end

-- Setup function to be called from your init.lua
M.setup = function(filetype_to_target)
  -- Store the filetype(s) to target if passed, otherwise default to 'lua'
  M.target_filetype = filetype_to_target or "lua"

  -- Create a dedicated autocmd group to avoid duplicate autocommands
  local fold_group = vim.api.nvim_create_augroup("TreesitterDynamicFold", { clear = true })

  -- Autocommand to initially fold everything on BufReadPost for the target filetype
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = fold_group,
    pattern = "*." .. M.target_filetype, -- Adjust pattern based on M.target_filetype
    callback = function()
      -- Set buffer-local options for initial collapse
      vim.opt_local.foldenable = true
      vim.opt_local.foldlevel = 0
      -- Clear the last unfolded node for this buffer
      last_unfolded_node_info[vim.api.nvim_get_current_buf()] = nil
    end,
    desc = "Initial autofold all on special file entry",
  })

  -- Autocommand to handle dynamic folding/unfolding on cursor movement
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = fold_group,
    pattern = "*." .. M.target_filetype, -- Adjust pattern based on M.target_filetype
    callback = handle_cursor_moved,
    desc = "Dynamic Treesitter fold/unfold on cursor move",
  })

  -- Autocommand to reset when leaving the buffer
  vim.api.nvim_create_autocmd("BufLeave", {
    group = fold_group,
    pattern = "*." .. M.target_filetype, -- Adjust pattern based on M.target_filetype
    callback = function()
      local buf_id = vim.api.nvim_get_current_buf()
      last_unfolded_node_info[buf_id] = nil
    end,
    desc = "Clean up dynamic fold state on BufLeave",
  })

  -- Also handle when the buffer is wiped out
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = fold_group,
    pattern = "*." .. M.target_filetype, -- Adjust pattern based on M.target_filetype
    callback = function()
      local buf_id = vim.api.nvim_get_current_buf()
      last_unfolded_node_info[buf_id] = nil
    end,
    desc = "Clean up dynamic fold state on BufWipeout",
  })
end

return M
