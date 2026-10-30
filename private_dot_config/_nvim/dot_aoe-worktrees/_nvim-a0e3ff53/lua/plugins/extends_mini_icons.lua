return {
  {
    "echasnovski/mini.icons",
    version = false,
    opts = function(_, opts)
      opts.extension = {
        -- lua = { hl = "Special" },
        ["http"] = { glyph = "󰡷", hl = "MiniIconsGreen" },
        ["props"] = { glyph = "󰗀", hl = "MiniIconsOrange" },
        ["config"] = { glyph = "", hl = "MiniIconsOrange" },
      }
    end,
  },
}
