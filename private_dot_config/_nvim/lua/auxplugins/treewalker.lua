-- vim.cmd("set <LAlt-b>=\\x1b[<LAlt-h>]")

-- 2. Now, map the newly defined key names
vim.keymap.set("n", "\x1bh", '<Cmd>echo "Left Alt-h pressed"<CR>', {
  noremap = true,
  silent = true,
  desc = "Test Left Alt-h",
})
vim.keymap.set("n", "M-h", '<Cmd>echo "Left Alt-h pressed"<CR>', {
  noremap = true,
  silent = true,
  desc = "Test Left Alt-h",
})

vim.keymap.set({ "n", "v" }, "<A-K>", "<cmd>Treewalker Up<cr>", { silent = true })
vim.keymap.set({ "n", "v" }, "<A-H>", "<cmd>Treewalker Left<cr>", { silent = true })
vim.keymap.set({ "n", "v" }, "<A-J>", "<cmd>Treewalker Down<cr>", { silent = true })
vim.keymap.set({ "n", "v" }, "<A-L>", "<cmd>Treewalker Right<cr>", { silent = true })

-- swapping
vim.keymap.set("n", "<leader>TD", "<cmd>Treewalker SwapDown<cr>", { silent = true })
vim.keymap.set("n", "<leader>TS", "<cmd>Treewalker SwapUp<cr>", { silent = true })
vim.keymap.set("n", "<leader>TL", "<cmd>Treewalker SwapLeft<cr>", { silent = true })
vim.keymap.set("n", "<leader>TR", "<cmd>Treewalker SwapRight<cr>", { silent = true })
return {
  "aaronik/treewalker.nvim",

  -- The following options are the defaults.
  -- Treewalker aims for sane defaults, so these are each individually optional,
  -- and setup() does not need to be called, so the whole opts block is optional as well.
  config = function()
    -- movement
  end,
  opts = {
    -- Whether to briefly highlight the node after jumping to it
    highlight = true,

    -- How long should above highlight last (in ms)
    highlight_duration = 250,

    -- The color of the above highlight. Must be a valid vim highlight group.
    -- (see :h highlight-group for options)
    highlight_group = "CursorLine",

    -- Whether the plugin adds movements to the jumplist -- true | false | 'left'
    --  true: All movements more than 1 line are added to the jumplist. This is the default,
    --        and is meant to cover most use cases. It's modeled on how { and } natively add
    --        to the jumplist.
    --  false: Treewalker does not add to the jumplist at all
    --  "left": Treewalker only adds :Treewalker Left to the jumplist. This is usually the most
    --          likely one to be confusing, so it has its own mode.
    jumplist = true,
  },
}
