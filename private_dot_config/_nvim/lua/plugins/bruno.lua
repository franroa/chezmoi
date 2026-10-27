return {
  {
    "romek-codes/bruno.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Pickers
      -- Choose one based on whichever picker you prefer.
      "nvim-telescope/telescope.nvim",
      -- Or
      -- "ibhagwan/fzf-lua",
      -- Or
      -- {
      --     "folke/snacks.nvim",
      --     opts = { picker = { enabled = true } },
      -- },
    },
    config = function()
      require("bruno").setup({
        -- Paths to your bruno collections.
        collection_paths = {
          { name = "Main", path = "/home/froa/Projects/ts/qa-poc-test-api.git/branches/main/Bruno" },
        },
        -- Which picker to use, "fzf-lua" or "snacks" are also allowed.
        picker = "snacks",
        -- If output should be formatted by default.
        show_formatted_output = true,
        -- If formatting fails for whatever reason, don't show error message (will always fallback to unformatted output).
        suppress_formatting_errors = false,
      })
    end,
  },
}
