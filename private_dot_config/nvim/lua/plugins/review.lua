return {
  "georgeguimaraes/review.nvim",
  dependencies = {
    "esmuellert/codediff.nvim",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("review").setup({
      comment_types = {
        note = { key = "n", name = "Note", icon = "📝", hl = "ReviewNote" },
        suggestion = { key = "s", name = "Suggestion", icon = "💡", hl = "ReviewSuggestion" },
        issue = { key = "i", name = "Issue", icon = "⚠️", hl = "ReviewIssue" },
        praise = { key = "p", name = "Praise", icon = "✨", hl = "ReviewPraise" },
      },
      keymaps = {
        add_note = "<localleader>cn",
        add_suggestion = "<localleader>cs",
        add_issue = "<localleader>ci",
        add_praise = "<localleader>cp",
        delete_comment = "<localleader>cd",
        edit_comment = "<localleader>ce",
        next_comment = "]n",
        prev_comment = "[n",
        toggle_file_panel = "f",
      },
      codediff = {
        readonly = true,
      },
    })
  end,
  cmd = { "Review" },
  keys = {
    { "<leader>r", "<cmd>Review<cr>", desc = "Review" },
    { "<leader>R", "<cmd>Review commits<cr>", desc = "Review commits" },
  },
  opts = {},
}
