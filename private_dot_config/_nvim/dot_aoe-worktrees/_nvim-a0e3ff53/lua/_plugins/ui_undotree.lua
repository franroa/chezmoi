vim.undotree_DiffCommand = "git diff --word-diff"
return {
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      {
        "<leader>uu",
        "<cmd>UndotreeToggle<cr>",
        desc = "undotree",
      },
    },
  },
}
