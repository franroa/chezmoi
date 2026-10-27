local M = {}

-- Store icons as { [line_number] = "icon text" }
-- We use 0-based line numbers internally.
M.icons = {}

function M.clear()
  M.icons = {}
end

function M.set(lnum, text)
  M.icons[lnum] = text
end

function M.get(lnum)
  return M.icons[lnum]
end

return M
