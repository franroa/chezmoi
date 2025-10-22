return {
  {
    "projekt0n/github-nvim-theme",
    vscode = true,
    cond = vim.g.started_by_firenvim == true,
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.cmd("colorscheme github_light")
    end,
  },
}
