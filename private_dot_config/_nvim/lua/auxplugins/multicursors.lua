return {
  "zaucy/mcos.nvim",
  dependencies = {
    "jake-stewart/multicursor.nvim",
  },
  config = function()
    local mcos = require("mcos")
    mcos.setup({})

    -- mcos doesn't setup any keymaps
    -- here are some recommended ones
    vim.keymap.set({ "n", "v" }, "gms", mcos.opkeymapfunc, { expr = true })
    vim.keymap.set({ "n" }, "gmss", mcos.bufkeymapfunc)
  end,
}
