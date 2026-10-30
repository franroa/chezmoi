vim.g.firenvim_config = {
  globalSettings = { alt = "all", cmdlineTimeout = 3000 },
  localSettings = {
    [".*"] = {
      cmdline = "neovim",
      content = "text",
      priority = 0,
      selector = "textarea",
      takeover = "always",
    },
  },
}

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "github.com_*.txt",
  command = "set filetype=markdown",
})

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  callback = function(e)
    if not vim.g.started_by_firenvim then
      return
    end

    if vim.g.timer_started == true then
      return
    end

    vim.g.timer_started = true
    vim.fn.timer_start(10000, function()
      vim.g.timer_started = false
      vim.cmd("write")
    end)
  end,
})

return {
  {
    vscode = true,
    "glacambre/firenvim",

    -- Lazy load firenvim
    -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
    lazy = false,
    build = function()
      require("lazy").load({ plugins = "firenvim", wait = true })
      vim.fn["firenvim#install"](0)
    end,
    keys = {
      {
        "<Esc><Esc>",
        "<Cmd>call firenvim#focus_page()<CR>",
        {},
      },
      {
        "<C-z>",
        "<Cmd>call firenvim#hide_frame()<CR>",
        {},
      },
    },
  },
}
