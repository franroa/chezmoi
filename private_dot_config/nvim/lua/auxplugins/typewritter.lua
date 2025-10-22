return {
  {
    "joshuadanpeterson/typewriter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("typewriter").setup({
        enable_notifications = true,
        keep_cursor_position = true,
        enable_horizontal_scroll = true,
        enable_with_zen_mode = true,
        enable_with_true_zen = true,
      })
    end,
    opts = {},
  },
}
