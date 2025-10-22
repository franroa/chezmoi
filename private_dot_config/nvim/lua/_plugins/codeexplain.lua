return {
  {
    "mthbernardes/codeexplain.nvim",
    lazy = true,
    cmd = "CodeExplain",
    build = function()
      vim.cmd([[silent UpdateRemotePlugins]])
    end,
  }
}
