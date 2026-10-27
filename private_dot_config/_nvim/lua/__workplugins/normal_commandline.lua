return {
  "jake-stewart/normal-cmdline.nvim",
  event = "CmdlineEnter",
  config = function()
    -- make the cmdline insert mode a beam
    vim.opt.guicursor:append("ci:ver1,c:ver1")

    local cmd = require("normal-cmdline")
    cmd.setup({
      -- key to hit within cmdline to enter normal mode:
      key = "<esc>",
      -- the cmdline text highlight when in normal mode:
      hl = "Normal",
      -- these mappings only apply to normal mode in cmdline:
      mappings = {
        ["k"] = cmd.history.prev,
        ["j"] = cmd.history.next,
        ["<cr>"] = cmd.accept,
        ["<esc>"] = cmd.cancel,
        ["<c-c>"] = cmd.cancel,
        [":"] = cmd.reset,
      },
    })
  end,
}
