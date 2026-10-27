-- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-operators.md
return {
  "gbprod/substitute.nvim",
  opts = function()
    -- Lua
    vim.keymap.set("n", "r", require("substitute").operator, { noremap = true })
    vim.keymap.set("n", "rL", require("substitute").line, { noremap = true })
    vim.keymap.set("n", "rl", require("substitute").eol, { noremap = true })
    vim.keymap.set("x", "r", require("substitute").visual, { noremap = true })

    vim.keymap.set("n", "rx", require("substitute.exchange").operator, { noremap = true })
    vim.keymap.set("n", "rxL", require("substitute.exchange").line, { noremap = true })
    vim.keymap.set("x", "rR", require("substitute.exchange").visual, { noremap = true })
    vim.keymap.set("n", "sxc", require("substitute.exchange").cancel, { noremap = true })
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  end,
}
