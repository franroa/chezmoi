return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",   -- required by telescope
      "MunifTanjim/nui.nvim",

      -- optional
      "nvim-tree/nvim-web-devicons",

      -- recommended
      -- "rcarriga/nvim-notify",
    },
    opts = {
      -- configuration goes here
    },
  }
}
