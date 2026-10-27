return {
  {
    "nvim-mini/mini.icons",
    version = false,
    opts = function(_, opts)
      opts.filetype = opts.filetype or {}
      opts.filetype["river"] = { glyph = "", hl = "MiniIconsOrange" }
      opts.filetype["alloy"] = { glyph = "", hl = "MiniIconsOrange" }

      opts.lsp = opts.lsp or {}
      opts.lsp["river"] = { glyph = "", hl = "MiniIconsOrange" }

      opts.extension = opts.extension or {}
      opts.extension["alloy"] = { glyph = "", hl = "MiniIconsOrange" }
    end,
  },
}
