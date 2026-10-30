return {
  {
    "ahmedkhalf/project.nvim",
    opts = {
      patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "*.env" },
    },
    event = "VeryLazy",
    config = function(_, opts)
      -- opts.manual_mode = false
      require("project_nvim").setup(opts)
      -- require("telescope").load_extension("projects")
    end,
    -- keys = {
    --   { "<leader>fp", "<Cmd>Telescope projects<CR>", desc = "Projects" },
    -- },
  },
}
