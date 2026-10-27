local M = {}

function M.UpdateDevIconsInDropbar()
  if vim.g.kubernetes_cluster == "" then
    require("dropbar").setup({
      icons = {
        kinds = { use_devicons = true },
      },
    })
    vim.cmd("colorscheme tokyonight")
    return
  end
  require("dropbar").setup({
    icons = {
      kinds = { use_devicons = false },
    },
  })
end

function M.UpdateHlValues()
  -- require("functions.kubernetes").UpdateGlobalValues()

  -- local cluster_fg = "Blue"
  -- local cluster_bg = "Yellow"
  -- local namespace_fg = "Red"
  -- local namespace_bg = "Yellow"
  -- local warning_fg = "Red"
  --
  -- vim.api.nvim_set_hl(0, "K8sCluster", { bold = true, fg = cluster_fg, bg = cluster_bg })
  -- vim.api.nvim_set_hl(0, "K8sNamespace", { bold = true, fg = namespace_fg, bg = namespace_bg })
  -- vim.api.nvim_set_hl(0, "WarningMsg", { bold = true, fg = warning_fg, bg = winbar_bg })
  --
  if vim.g.kubernetes_cluster == "kind-kind" then
    local winbar_bg = "#303b33"
    local treesitter_context = "#424b33"
    vim.api.nvim_set_hl(0, "Winbar", { bold = true, bg = winbar_bg })
    vim.api.nvim_set_hl(0, "WinbarNC", { bold = true, bg = winbar_bg })
    vim.api.nvim_set_hl(0, "TreesitterContext", { bold = true, bg = treesitter_context })
  end
  -- vim.api.nvim_set_hl(0, "dropbariconkindarray", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindboolean", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindbreakstatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindcall", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindcasestatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindclass", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindconstant", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindconstructor", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindcontinuestatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkinddeclaration", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkinddelete", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkinddostatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindelsestatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindenum", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindenummember", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindevent", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindfield", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindfile", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindfolder", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindforstatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindfunction", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindidentifier", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindifstatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindinterface", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindkeyword", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindlist", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmacro", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmarkdownh1", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmarkdownh2", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmarkdownh3", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmarkdownh4", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmarkdownh5", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmarkdownh6", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmethod", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindmodule", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindnamespace", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindnull", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindnumber", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindobject", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindoperator", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindpackage", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindproperty", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "dropbariconkindreference", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindRepeat", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindScope", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindSpecifier", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindStatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindString", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindStruct", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindSwitchStatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindType", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindTypeParameter", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindUnit", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindValue", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindVariable", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconKindWhileStatement", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconUIIndicator", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconUIPickPivot", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconUISeparator", { bg = winbar_bg })
  -- vim.api.nvim_set_hl(0, "DropBarIconUISeparatorMenu", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuCurrentContext", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuFloatBorder", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuHoverEntry", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuHoverIcon", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuHoverSymbol", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarMenuNormalFloat", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarPreview", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindArray", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindBoolean", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindBreakStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindCall", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindCaseStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindClass", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindConstant", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindConstructor", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindContinueStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindDeclaration", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindDelete", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindDoStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindElseStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindEnum", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindEnumMember", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindEvent", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindField", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindFile", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindFolder", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindForStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindFunction", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindIdentifier", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindIfStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindInterface", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindKeyword", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindList", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMacro", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMarkdownH1", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMarkdownH2", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMarkdownH3", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMarkdownH4", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMarkdownH5", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMarkdownH6", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindMethod", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindModule", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindNamespace", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindNull", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindNumber", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindObject", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindOperator", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindPackage", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindaProperty", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindReference", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindRepeat", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindScope", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindSpecifier", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindString", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindStruct", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindSwitchStatement", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindType", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindTypeParameter", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindUnit", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindValue", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindVariable", { bg = winbar_bg })
  vim.api.nvim_set_hl(0, "DropBarKindWhileStatement", { bg = winbar_bg })
end

function M.Redraw()
  if vim.g.kubernetes_cluster == "" or vim.g.kubernetes_cluster == nil then
    vim.opt.winbar = ""
    return
  end

  M.UpdateHlValues()

  -- TODO: Uncoment if you want to have winbar on starup
  -- if string.match(vim.g.kubernetes_cluster, "dev") then
  --   vim.opt.winbar = "%#K8sIcon# 󱃾 "
  --     .. "%#K8sCluster#"
  --     .. vim.g.kubernetes_cluster
  --     .. "%#K8sNamespace# ("
  --     .. vim.g.kubernetes_namespace
  --     .. ")"
  --     .. "%#WarningMsg#    %=%#WarningMsg#You Are On A Shared Cluster! %#WarningMsg#   "
  --   return
  -- end
  -- vim.opt.winbar = "%#K8sIcon# 󱃾 "
  --   .. "%#K8sCluster#"
  --   .. vim.g.kubernetes_cluster
  --   .. "%#K8sNamespace# ("
  --   .. vim.g.kubernetes_namespace
  --   .. ")"
end

return M
