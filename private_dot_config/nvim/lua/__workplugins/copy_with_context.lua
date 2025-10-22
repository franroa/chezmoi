return {
  "zhisme/copy_with_context.nvim",
  config = function()
    require("copy_with_context").setup({
      -- Customize mappings
      mappings = {
        relative = "<leader>cy",
        absolute = "<leader>cY",
      },
      -- whether to trim lines or not
      trim_lines = false,
      context_format = "# %s:%s", -- Default format for context: "# Source file: filepath:line"
    })
  end,
}
