-- ~/.config/nvim/lua/folds.lua

local M = {}

function M.fold_river_blocks()
  -- Ensure we are in a YAML file where injections are likely
  if vim.bo.filetype ~= "yaml" then
    vim.notify("Not a YAML file. Folding skipped.", vim.log.levels.INFO)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win() -- Get current window ID for window-local options

  -- Store the original fold method for the current window
  local original_foldmethod = vim.wo[winid].foldmethod

  -- Get the generic parser for the buffer. It will have access to all language trees.
  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    vim.notify("Tree-sitter parser not found for this buffer.", vim.log.levels.ERROR)
    -- Restore foldmethod if no parser is found
    vim.wo[winid].foldmethod = original_foldmethod
    -- vim.wo[winid].foldlevel = 99
    return
  end

  -- Step 1: Find the injected 'river' tree directly.
  -- We iterate over all trees managed by the parser for this buffer (the base language and any injected languages).
  local river_tree = nil
  parser:for_each_tree(function(tree, lang_tree)
    -- The `lang_tree` is a special object that represents a language.
    -- We can get its name using the `:lang()` method.
    if lang_tree:lang() == "river" then
      river_tree = tree
      -- Returning a non-nil value stops the iteration, making it more efficient.
      return true
    end
  end)

  if not river_tree then
    vim.notify(
      "No 'river' injected Tree-sitter tree found. Is the 'river' parser installed and are injections configured correctly?",
      vim.log.levels.WARN
    )
    -- Restore foldmethod if no river tree is found
    vim.wo[winid].foldmethod = original_foldmethod
    -- vim.wo[winid].foldlevel = 99
    return
  end

  local river_root_node = river_tree:root()
  if not river_root_node then
    vim.notify("River injected tree has no root node. Folding skipped.", vim.log.levels.WARN)
    -- Restore foldmethod if no root node is found
    vim.wo[winid].foldmethod = original_foldmethod
    vim.wo[winid].foldlevel = 99
    return
  end

  -- Step 2: Query for 'block' nodes within the 'river' tree.
  local folds_to_create = {}
  local river_block_query_string = [[
    (block) @river_block
  ]]

  local river_block_query = vim.treesitter.query.parse("river", river_block_query_string)
  if not river_block_query then
    vim.notify("Error parsing River block query.", vim.log.levels.ERROR)
    -- Restore foldmethod if query parsing fails
    vim.wo[winid].foldmethod = original_foldmethod
    -- vim.wo[winid].foldlevel = 99
    return
  end

  -- Iterate over captures to find all 'block' nodes in the 'river' tree.
  -- node:range() returns 0-indexed values for start_row, start_col, end_row, end_col.
  -- For vim commands like :fold, lines are 1-indexed and the end_row is inclusive.
  -- Treesitter's end_row is typically the row *after* the last line of the node.
  -- So if a node is on lines 0, 1, 2, range might be (0,x,3,y). We need to fold 1,3 (1-indexed).
  for id, node in river_block_query:iter_captures(river_root_node, bufnr) do
    if river_block_query.captures[id] == "river_block" then
      local start_row, _, end_row_exclusive, _ = node:range()
      -- Ensure it's a multi-line block to create a fold
      -- A fold requires at least two lines. If start_row is 0 and end_row_exclusive is 1, it's one line.
      -- So, end_row_exclusive must be greater than start_row + 1 for a valid multi-line fold.
      if end_row_exclusive > start_row + 1 then
        -- start_line is 1-indexed: start_row + 1
        -- end_line is 1-indexed inclusive: end_row_exclusive
        table.insert(folds_to_create, { start_row + 1, end_row_exclusive })
      end
    end
  end

  if #folds_to_create == 0 then
    vim.notify("No River blocks found to fold.", vim.log.levels.INFO)
    -- Restore foldmethod even if no folds are created
    vim.wo[winid].foldmethod = original_foldmethod
    -- vim.wo[winid].foldlevel = 99
    return
  end

  -- Step 3: Apply folds
  -- Temporarily set fold method to manual to allow programmatic fold creation
  vim.wo[winid].foldmethod = "manual"
  vim.cmd([[normal! zE]]) -- Unfold everything to clear any existing manual folds

  -- Apply the newly found folds
  for _, fold_range in ipairs(folds_to_create) do
    local start_line = fold_range[1]
    local end_line = fold_range[2] -- This is now the correct 1-indexed inclusive end line
    -- The fold command includes the end line. We now use the 'end_line' directly.
    vim.api.nvim_command(string.format("%d,%dfold", start_line, end_line + 1))
  end

  -- After creating all folds, close them to start with a tidy view
  vim.cmd([[normal! zM]])
  vim.notify("River blocks folding applied.", vim.log.levels.INFO)

  vim.cmd([[UfoDisable]])

  -- Restore the original fold method
  vim.wo[winid].foldmethod = "manual"
  -- vim.wo[winid].foldlevel = 99
end

-- Expose the function via a user command only
-- The autocommand has been removed as per your request.
vim.api.nvim_create_user_command("FoldRiver", M.fold_river_blocks, {})

return M
