-- Agent of Empires (AoE) integration
-- https://github.com/njbrake/agent-of-empires

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<A-3>",
        function()
          Snacks.terminal.open("aoe", {
            cwd = LazyVim.root.git(),
            use_shell = false,
            auto_close = true,
            start_insert = false,
            auto_insert = false,
            win = {
              position = "float",
              height = 0.9,
              width = 0.9,
              border = "rounded",
            },
          })
        end,
        desc = "Agent of Empires",
        mode = { "n", "t" },
      },
    },
  },
}
