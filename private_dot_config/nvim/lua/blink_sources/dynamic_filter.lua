-- File: lua/custom/sources/dynamic_filter.lua
-- A generic source that displays suggestions with icons.

--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

-- This table will hold the suggestions passed from the calling script.
local external_suggestions = {}

-- This function now expects a list of tables, e.g., { { label = "...", icon = "..." }, ... }
function source.set_suggestions(suggestions_list)
  if type(suggestions_list) == "table" then
    external_suggestions = suggestions_list
  else
    external_suggestions = {}
  end
end

-- This function clears the suggestions to prevent state leakage.
function source.clear_suggestions()
  external_suggestions = {}
end

function source.new(_)
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == "dynamic_filter"
end

function source:get_completions(_, callback)
  --- @type lsp.CompletionItem[]
  local items = {}
  local cmp_item_kind = require("blink.cmp.types").CompletionItemKind

  for _, suggestion in ipairs(external_suggestions) do
    if suggestion and suggestion.label then
      local label = suggestion.label
      -- Default to a space if no icon is provided, for alignment.
      local icon = suggestion.icon or " "

      table.insert(items, {
        -- The final text shown in the menu includes the icon.
        label = icon .. "  " .. label,
        -- The text to actually insert should NOT have the icon.
        insertText = label,
        -- The text used for fuzzy matching should also NOT have the icon.
        filterText = label,
        kind = cmp_item_kind.Text,
      })
    end
  end

  callback({ items = items })
end

function source:resolve(item, callback)
  callback(item)
end

return source
