return {
  {
    "glepnir/template.nvim",
    cmd = { "Template", "TemProject" },
    config = function()
      vim.g.entityname = "RuleException"
      require("template").setup({
        temp_dir = "~/.config/nvim/templates",
        -- author,
        -- email, -- email address
      })
    end,
  },
}
