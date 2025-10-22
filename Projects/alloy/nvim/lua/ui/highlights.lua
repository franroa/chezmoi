local M = {}

M.tokyonight_futuristic_hls = {
  key_order = { "Sky", "Green", "Coral", "Lavender", "Teal", "Storm" },
  Storm = { fg = "#7aa2f7" },
  Teal = { fg = "#73daca" },
  Green = { fg = "#9ece6a" },
  Lavender = { fg = "#bb9af7" },
  Sky = { fg = "#89ddff" },
  Coral = { fg = "#ff9e64" },
  Follow = { bg = "#3b4261" },
  Dimmed = { fg = "#565f89" },
  Filter = { link = "@punctuation.special" },
  FilterInactive = { link = "Comment" },
  StageHeader = { fg = "#e0af68", bold = true },
  ComponentBaseText = { fg = "#a9b1d6" },
  ComponentTypeBold = { link = "@type.builtin" },
  ComponentLabelDim = { link = "Comment" },
  BranchIcon = { fg = "#f7768e" },
  TreeConnector = { fg = "#3b4261" },
  Arrow = { link = "TreeConnector" },
  BorderChars = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
}

M._highlights_set = false

function M.setup_highlights()
  if M._highlights_set then
    return
  end

  local pipeline_hls = M.tokyonight_futuristic_hls

  for name, hl_definition in pairs(pipeline_hls) do
    if name ~= "key_order" and name ~= "Arrow" and name ~= "BorderChars" then
      local diagram_hl_name = "DiagramBox" .. name
      vim.api.nvim_set_hl(0, diagram_hl_name, hl_definition)
    end
  end

  vim.api.nvim_set_hl(0, "DiagramDimmedText", pipeline_hls.Dimmed)
  vim.api.nvim_set_hl(0, "DiagramArrow", pipeline_hls.Arrow)
  vim.api.nvim_set_hl(0, "DiagramBorder", { fg = pipeline_hls.Storm.fg })
  vim.api.nvim_set_hl(0, "DiagramBoxSuccess", { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "DiagramBoxFailure", { fg = "#f7768e" })
  vim.api.nvim_set_hl(0, "PopupBorder", { fg = pipeline_hls.Storm.fg })
  -- Use vim.cmd for proper full-line background highlighting
  vim.cmd("highlight AlloyDiffAdd guibg=#24332A ctermbg=22")
  vim.cmd("highlight AlloyDiffDelete guibg=#392A30 ctermbg=52")
  vim.api.nvim_set_hl(0, "AlloyOverrideIcon", { fg = "#e0af68", bg = "NONE", default = true })
  vim.api.nvim_set_hl(0, "AlloyPipelineNumber", { fg = "#89ddff", bold = true })
  vim.api.nvim_set_hl(0, "AlloyTestedPipelineHighlight", { bg = "#2e3c64" })

  M._highlights_set = true
end

return M
