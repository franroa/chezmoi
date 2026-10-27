-- Register the tree-sitter-river grammar (https://github.com/franroa/tree-sitter-river)
-- as a custom parser so nvim-treesitter (main branch) can install/build it.
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").river = {
      install_info = {
        url = "https://github.com/franroa/tree-sitter-river",
        queries = "queries",
      },
    }
  end,
})

-- Alloy config files are parsed with the river grammar.
vim.treesitter.language.register("river", "alloy")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "river" })
    end,
  },
}
