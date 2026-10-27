return {
  "hedyhli/outline.nvim",
  lazy = true,
  dependencies = {
    "bngarren/outline-test-blocks-provider.nvim",
  },
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
  },
  opts = {
    -- Add the "test_blocks" provider before "lsp"
    providers = {
      priority = { "test_blocks", "lsp", "coc", "markdown", "norg" },
      -- Configure the test_blocks provider here:
      test_blocks = {
        enable = { describe = true, it = true, pending = false },
        max_depth = 5,
      },
    },
  },
}
