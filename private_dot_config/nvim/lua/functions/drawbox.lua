local M = {}
-- Draws a dynamic chain of boxes based on a table of labels.
-- @param labels A table of strings, where each string is the text for a box.
--               Example: {"Parse", "Compile", "Execute"}
function M.DrawDynamicBoxChain(labels)
  -- 1. Validate the input
  if labels == nil or #labels == 0 then
    print("Error: DrawDynamicBoxChain requires a list of labels.")
    return
  end

  -- 2. Define the building blocks
  local top_parts = {}
  local middle_parts = {}
  local bottom_parts = {}
  local arrow = " ──> "

  -- 3. Iterate through labels and build each box and connector
  for i, label in ipairs(labels) do
    local text_width = vim.fn.strwidth(label) -- Use strwidth for multi-byte chars
    local box_inner_width = text_width + 2 -- Add padding for │ text │
    local horizontal_line = string.rep("─", box_inner_width)

    -- Create the parts for this box
    table.insert(top_parts, "┌" .. horizontal_line .. "┐")
    table.insert(middle_parts, "│ " .. label .. " │")
    table.insert(bottom_parts, "└" .. horizontal_line .. "┘")

    -- Add a connecting arrow if it's not the last box
    if i < #labels then
      table.insert(top_parts, string.rep(" ", vim.fn.strwidth(arrow)))
      table.insert(middle_parts, arrow)
      table.insert(bottom_parts, string.rep(" ", vim.fn.strwidth(arrow)))
    end
  end

  -- 4. Assemble the final drawing from the parts
  local final_top = table.concat(top_parts)
  local final_middle = table.concat(middle_parts)
  local final_bottom = table.concat(bottom_parts)

  local chain_content = { final_top, final_middle, final_bottom }

  -- 5. Create a buffer and place our drawing in it
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, chain_content)

  -- 6. Calculate dimensions and open the centered floating window
  local screen_width = vim.api.nvim_get_option("columns")
  local screen_height = vim.api.nvim_get_option("lines")

  local win_width = vim.fn.strwidth(final_top) -- Dynamic width
  local win_height = #chain_content -- Always 3 in this case

  local row = math.floor((screen_height - win_height) / 2)
  local col = math.floor((screen_width - win_width) / 2)

  local opts = {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "none",
  }
  vim.api.nvim_open_win(buf, true, opts)
end

return M
