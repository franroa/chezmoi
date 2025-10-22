local marks_fix_group = vim.api.nvim_create_augroup("marks-fix-hl", {})
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = marks_fix_group,
  callback = function()
    vim.api.nvim_set_hl(0, "MarkSignNumHL", {})
  end,
})

return {
  {
    "mawkler/modicator.nvim",
    dependencies = "folke/tokyonight.nvim", -- Add your colorscheme plugin here
    init = function()
      -- These are required for Modicator to work
      vim.o.cursorline = true
      vim.o.number = true
      vim.o.termguicolors = true
    end,
    opts = {
      -- Show warning if any required option is missing
      show_warnings = true,
      highlights = {
        -- Default options for bold/italic
        defaults = {
          bold = true,
          italic = true,
        },
        groups = {
          ["i"] = {
            bold = true,
            italic = true,
          },
          ["n"] = {
            bold = true,
            italic = true,
          },
          ["v"] = {
            bold = true,
            italic = true,
          },
          ["V"] = {
            bold = true,
            italic = true,
          },
          [""] = {
            bold = true,
            italic = true,
          },
        },
      },
      integration = {
        lualine = {
          enabled = true,
          -- Name of lualine section to use (if `nil`, gets detected automatically)
          mode_section = nil,
          -- Whether to use lualine's mode highlight's foreground or background
          highlight = "bg",
        },
      },
    },
  },
}
