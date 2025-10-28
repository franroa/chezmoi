vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").repro({
  spec = {
    { "nvim-lua/plenary.nvim", lazy = true },
    { "nvim-neotest/nvim-nio", lazy = true },
    "nvim-treesitter/nvim-treesitter",
    { "nsidorenco/neotest-vstest", lazy = true },
    {
      "nvim-neotest/neotest",
      opts = function()
        return {
          adapters = {
            require("neotest-vstest"),
          },
          log_level = 0,
        }
      end,
    },
  },
})

require("nvim-treesitter.configs").setup({
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c_sharp", "fsharp" },
})

-- do anything else you need to do to reproduce the issue
