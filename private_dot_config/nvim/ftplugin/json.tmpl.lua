vim.keymap.set("n", "o", function()
  return require("functions.json").add_trailing_comma_if_needed()
end, { buffer = true, expr = true })
