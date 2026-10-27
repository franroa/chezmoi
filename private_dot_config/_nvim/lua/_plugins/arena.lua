-- TODO: alternative: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-visits.md
return {
  {
    "dzfrias/arena.nvim",
    event = "BufWinEnter",
    keys = {
      {
        "<leader>ba",
        function()
          require("arena").toggle()
        end,
        desc = "Arena",
      },
    },
    -- Calls `.setup()` automatically
    config = true,
  },
}
