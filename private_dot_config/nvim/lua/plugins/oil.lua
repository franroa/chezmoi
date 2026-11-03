function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    -- If there is no current directory (e.g. over ssh), just show the buffer name
    return vim.api.nvim_buf_get_name(0)
  end
end

local detail = false

return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    keys = {
      { "<space>e", "<cmd>Oil --float<cr>", desc = "Oil (float)" },
    },
    opts = {
      view_options = {
        show_hidden = true,
        is_hidden_file = function(name, bufnr)
          local m = name:match("^%.")
          return m ~= nil
        end,
        is_always_hidden = function(name, bufnr)
          return false
        end,
        natural_order = "fast",
        case_insensitive = false,
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },
      win_options = {
        signcolumn = "yes:2",
        winbar = "%!v:lua.get_oil_winbar()",
      },
      float = {
        get_win_title = nil,
        max_width = 0,
        preview_split = "right",
        border = "rounded",
        override = function(conf)
          return conf
        end,
      },
      preview_win = { border = "rounded" },
      confirmation = { border = "rounded" },
      progress = { border = "rounded" },
      ssh = { border = "rounded" },
      keymaps_help = { border = "rounded" },
      keymaps = {
        ["q"] = { "actions.close", desc = "Close Oil" },
        ["gd"] = {
          desc = "Toggle file detail view",
          callback = function()
            detail = not detail
            if detail then
              require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
            else
              require("oil").set_columns({ "icon" })
            end
          end,
        },
        ["<C-r>"] = '<cmd>lua require("oil").select({close=false, tab=true})<cr>',
      },
    },
  },
  {
    "benomahony/oil-git.nvim",
    dependencies = { "stevearc/oil.nvim" },
  },
  {
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    config = true,
  },
  {
    "JezerM/oil-lsp-diagnostics.nvim",
    dependencies = { "stevearc/oil.nvim" },
    opts = {},
  },
}
