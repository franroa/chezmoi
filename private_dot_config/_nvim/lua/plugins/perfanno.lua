return {
  "t-troebst/perfanno.nvim",
  opts = function()
    local perfanno = require("perfanno")
    local util = require("perfanno.util")

    return {
      line_highlights = util.make_bg_highlights(nil, "#CC3300", 10),
      vt_highlight = util.make_fg_highlight("#CC3300"),
    }
  end,
  config = function(_, opts)
    local perfanno = require("perfanno")
    perfanno.setup(opts)

    local keymap = vim.api.nvim_set_keymap
    local kopts = { noremap = true, silent = true }

    keymap("n", "<LEADER>plf", ":PerfLoadFlat<CR>", kopts)
    keymap("n", "<LEADER>plg", ":PerfLoadCallGraph<CR>", kopts)
    keymap("n", "<LEADER>plo", ":PerfLoadFlameGraph<CR>", kopts)

    keymap("n", "<LEADER>pe", ":PerfPickEvent<CR>", kopts)

    keymap("n", "<LEADER>pa", ":PerfAnnotate<CR>", kopts)
    keymap("n", "<LEADER>pf", ":PerfAnnotateFunction<CR>", kopts)
    keymap("v", "<LEADER>pa", ":PerfAnnotateSelection<CR>", kopts)

    keymap("n", "<LEADER>pt", ":PerfToggleAnnotations<CR>", kopts)

    keymap("n", "<LEADER>ph", ":PerfHottestLines<CR>", kopts)
    keymap("n", "<LEADER>ps", ":PerfHottestSymbols<CR>", kopts)
    keymap("n", "<LEADER>pc", ":PerfHottestCallersFunction<CR>", kopts)
    keymap("v", "<LEADER>pc", ":PerfHottestCallersSelection<CR>", kopts)
  end,
}
