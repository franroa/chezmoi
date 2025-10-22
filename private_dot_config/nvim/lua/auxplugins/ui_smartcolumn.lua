vim.fn.timer_start(2000, function()
  vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#30364A", ctermbg = 15, blend = 30 })
end)

return {
  {
    "m4xshen/smartcolumn.nvim",
    event = "BufRead",
    opts = {
      colorcolumn = "80",
      disabled_filetypes = {
        "NeogitCommitView",
        "NeogitLogView",
        "help",
        "text",
        "markdown",
        "mason",
        "lspinfo",
        "dashboard",
        "lazy",
        "gitconfig",
        "dbout",
      },
      custom_colorcolumn = {},
      scope = "file",
    },
  },
}
