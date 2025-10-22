return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    ---@type python.Config
    opts = { ---@diagnostic disable-line: missing-fields`
      python_lua_snippets = true,
    },
    dependencies = {
      { "mfussenegger/nvim-dap" },
      { "mfussenegger/nvim-dap-python" },
      { "neovim/nvim-lspconfig" },
      { "MunifTanjim/nui.nvim" },
      { "L3MON4D3/LuaSnip" },
    },
  },
}
