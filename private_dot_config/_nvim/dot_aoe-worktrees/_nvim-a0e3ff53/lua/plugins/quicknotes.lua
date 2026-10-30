return {
  "davmacario/nvim-quicknotes",
  -- >>> The following are optionals, to enable lazy loading
  keys = { "<leader>qn" },
  cmd = { "Quicknotes", "QuicknotesClear", "QuicknotesCleanup" }, -- Lazy-load the plugin
  -- <<<

  config = function()
    require("nvim-quicknotes").setup()

    -- Custom keymap
    vim.keymap.set("n", "<leader>qn", vim.cmd.Quicknotes, { desc = "Open quicknotes" })
  end,
}
