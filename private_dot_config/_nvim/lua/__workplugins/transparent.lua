return {
  "xiyaowong/nvim-transparent",
  config = function()
    require("transparent").setup({
      extra_groups = { -- table/string: additional groups that should be cleared
        "BufferLineTabClose",
        "BufferlineBufferSelected",
        "BufferLineFill",
        "BufferLineBackground",
        "BufferLineSeparator",
        "BufferLineIndicatorSelected",
        "BufferLine",

        "IndentBlanklineChar",

        -- make floating windows transparent
        "LspFloatWinNormal",
        "Normal",
        "NotifyINFOBody",
        "NotifyINFOBorder",
        "NotifyINFOTitle",
        "NotifyINFOIcon",
        "NormalFloat",
        "FloatBorder",
        "TelescopeNormal",
        "TelescopeBorder",
        "TelescopePromptBorder",
        "SagaBorder",
        "SagaNormal",
        "LspFloatWinBorder",
        "FidgetTitle",
        "FidgetTask",
      },
    })
  end,
}
