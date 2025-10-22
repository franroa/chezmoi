return {
  "shortcuts/no-neck-pain.nvim",
  opts = {
    buffers = {

      colors = {
        -- Hexadecimal color code to override the current background color of the buffer. (e.g. #24273A)
        -- Transparent backgrounds are supported by default.
        -- popular theme are supported by their name:
        -- - catppuccin-frappe
        -- - catppuccin-frappe-dark
        -- - catppuccin-latte
        -- - catppuccin-latte-dark
        -- - catppuccin-macchiato
        -- - catppuccin-macchiato-dark
        -- - catppuccin-mocha
        -- - catppuccin-mocha-dark
        -- - github-nvim-theme-dark
        -- - github-nvim-theme-dimmed
        -- - github-nvim-theme-light
        -- - rose-pine
        -- - rose-pine-dawn
        -- - rose-pine-moon
        -- - tokyonight-day
        -- - tokyonight-moon
        -- - tokyonight-night
        -- - tokyonight-storm
        ---@type string?
        background = "#2427AA",
        -- Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
        ---@type integer
        blend = 0.5,
        -- Hexadecimal color code to override the current text color of the buffer. (e.g. #7480c2)
        ---@type string?
        text = nil,
      },
    },
  },
  -- config = function()
  --   require("lazy").setup()
  -- end,
}
