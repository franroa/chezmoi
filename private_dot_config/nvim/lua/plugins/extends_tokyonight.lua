return {
  "tokyonight.nvim",
  opts = {
    transparent = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
    on_colors = function(colors)
      colors.bg_statusline = "NONE"

      -- require("functions.tokyonight-colors").UpdateTokyoNightColors()
    end,
  },
}
