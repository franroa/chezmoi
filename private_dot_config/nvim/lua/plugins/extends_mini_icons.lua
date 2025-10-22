return {
  {
    "nvim-mini/mini.icons",
    version = false,
    opts = function(_, opts)
      opts.extension = {
        -- lua = { hl = "Special" },
        ["http"] = { glyph = "󰡷", hl = "MiniIconsGreen" },
        ["props"] = { glyph = "󰗀", hl = "MiniIconsOrange" },
        ["config"] = { glyph = "", hl = "MiniIconsOrange" },
        ["alloy"] = { glyph = "", hl = "MiniIconsOrange" },
        ["river"] = { glyph = "", hl = "MiniIconsOrange" },
        ["service"] = { glyph = "󰢍", hl = "MiniIconsOrange" },
        ["sh"] = { glyph = "󱆃", hl = "MiniIconsGreen" },
        ["fish"] = { glyph = "󰈺", hl = "MiniIconsBlue" },
        ["log"] = { glyph = "󱂅", hl = "MiniIconsBlue" },

        -- ["prometheus"] = { glyph = "", hl = "MiniIconsOrange" },
      }

      opts.lsp = {
        ["river"] = { glyph = "", hl = "MiniIconsOrange" },
      }

      opts.filetype = {
        ["river"] = { glyph = "", hl = "MiniIconsOrange" },
        ["alloy"] = { glyph = "", hl = "MiniIconsOrange" },
      }

      opts.file = {
        ["localtest.alloy"] = { glyph = "", hl = "MiniIconsBlue" },
        ["Taskfile.yaml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["Taskfile.terraform.yaml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["Taskfile.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["Taskfile.terraform.yml"] = { glyph = "", hl = "MiniIconsBlue" },
      }
    end,
  },
}
