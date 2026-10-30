-- K / gd on `${var}` in terraform templatefile() yaml (*.tpl) resolve to the terraform argument
-- (functions/tftpl.lua); anywhere else they behave as LazyVim's defaults.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      yamlls = {
        keys = {
          {
            "K",
            function()
              local tftpl = require("functions.tftpl")
              if tftpl.is_tpl(0) then
                return tftpl.hover(0)
              end
              return vim.lsp.buf.hover()
            end,
            desc = "Hover",
          },
          {
            "gd",
            function()
              local tftpl = require("functions.tftpl")
              if tftpl.is_tpl(0) then
                return tftpl.definition(0)
              end
              return Snacks.picker.lsp_definitions()
            end,
            desc = "Goto Definition",
          },
        },
      },
    },
  },
}
