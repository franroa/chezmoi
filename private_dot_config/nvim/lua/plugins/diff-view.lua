-- https://github.com/kevinhwang91/nvim-ufo/issues/57
vim.api.nvim_create_user_command("DiffInline", function()
  vim.cmd("vsp")
  vim.cmd("term git diff | delta")
  vim.cmd("startinsert")
end, {})

-- Open inline diff for changes in the current file in a vertical split
vim.api.nvim_create_user_command("DiffInlineFile", function()
  local current_file = vim.fn.expand("%")
  vim.cmd("vsp")
  vim.cmd("term git diff -- " .. vim.fn.shellescape(current_file) .. " | delta")
  vim.cmd("startinsert")
end, {})

return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    lazy = false,
    config = { -- TODO: this is not working: https://www.reddit.com/r/neovim/comments/17pa517/githublike_highlighting_in_diffviewnvim/
      enhanced_diff_hl = true,
      hooks = {
        diff_buf_win_enter = function(bufnr, winid, ctx)
          if ctx.layout_name:match("^diff2") then
            if ctx.symbol == "a" then
              vim.opt_local.winhl = table.concat({
                "DiffAdd:DiffviewDiffAddAsDelete",
                "DiffDelete:DiffviewDiffDelete",
              }, ",")
            elseif ctx.symbol == "b" then
              vim.opt_local.winhl = table.concat({
                "DiffDelete:DiffviewDiffDelete",
              }, ",")
            end
          end
        end,
      },
    },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    keys = {
      { "<leader>gd", "", desc = "+diffview", mode = { "n", "v" } },
      -- { "<leader>gD", "<cmd>:tab Git diff %<cr>", desc = "Delta Diff" },
      { "<leader>gD", "<cmd>:tab :terminal env DELTA_FEATURES='+side-by-side' git diff %<cr>", desc = "Delta Diff" },
      { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
      {
        "<leader>gdh",
        function()
          vim.cmd("DiffviewFileHistory %")
        end,
        desc = "Diffview File History",
      },
    },
  },
}
