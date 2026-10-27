-- test
-- asfasdf
-- asfasdfsadf
-- asd adsf adsf
-- asdf
-- asdfsd
-- asd
-- sdf
-- sdf
vim.opt.foldminlines = 0 -- Allow folding/hiding single lines
vim.opt.fillchars = "fold: " -- Remove the trailing dots
return {
  "soemre/commentless.nvim",
  cmd = "Commentless",
  keys = {
    {
      "<leader>/",
      function()
        require("commentless").toggle()
      end,
      desc = "Toggle Comments",
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- Customize Configuration
  },
}
