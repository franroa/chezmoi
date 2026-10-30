vim.g.is_coverage_loaded = false

return {
  "andythigpen/nvim-coverage",
  requires = "nvim-lua/plenary.nvim",
  -- Optional: needed for PHP when using the cobertura parser
  -- rocks = { "lua-xmlreader" }, TODO:
  lazy = false,
  config = function()
    require("coverage").setup({
      -- load_coverage_cb = function(ftype)
      --   vim.notify("Loaded " .. ftype .. " coverage")
      -- end,
      highlights = {
        covered = {
          fg = "#98FB98",
        },
      },
      -- coverage_file = LazyVim.root.git() .. "/../../coverage/lcov.info",
      -- auto_reload = true,
    })
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      pattern = "*.cs",
      callback = function()
        if vim.g.is_coverage_loaded then
          require("coverage").load_lcov(LazyVim.root.git() .. "/../../coverage/lcov.info")
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>Ct",
      function()
        require("coverage").load_lcov(LazyVim.root.git() .. "/../../coverage/lcov.info")
        require("coverage").toggle()
        vim.g.is_coverage_loaded = not vim.g.is_coverage_loaded
      end,
      desc = "Toggle coverage",
      mode = "n",
    },
    {
      "<leader>Cs",
      function()
        if not vim.g.is_coverage_loaded then
          require("coverage").load_lcov(LazyVim.root.git() .. "/../../coverage/lcov.info")
          vim.g.is_coverage_loaded = false
        end
        require("coverage").summary()
      end,
      desc = "Open Summary",
      mode = "n",
    },
  },
}
