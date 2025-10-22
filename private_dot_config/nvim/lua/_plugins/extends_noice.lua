-- local set_hl_for_floating_window = function()
--   vim.api.nvim_set_hl(0, "NormalFloat", {
--     link = "Normal",
--   })
--   vim.api.nvim_set_hl(0, "FloatBorder", {
--     bg = "none",
--   })
-- end
--
-- set_hl_for_floating_window()
--
-- vim.api.nvim_create_autocmd("ColorScheme", {
--   pattern = "*",
--   desc = "Avoid overwritten by loading color schemes later",
--   callback = set_hl_for_floating_window,
-- })
return {
  {
    "folke/noice.nvim",
    vscode = true,
    opts = {
      -- lsp = {
      --   progress = { enabled = false },
      -- },
      views = {
        mini = {
          win_options = {
            winblend = 0,
          },
        },
        lsp = {
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
          },
        },
        -- you can enable a preset for easier configuration
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false, -- add a border to hover docs and signature help
        },
      },
    },
  },
}
