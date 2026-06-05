return {
  "sbulav/jira-oil.nvim",
  config = function()
    require("jira-oil").setup({
      cli = {
        issues = {
          team_jql = "project in (SDI2402, P0004) AND assignee = currentUser()",
          status_jql = 'status not in ("Done", "Closed", "Resolved")',
        },
      },
      defaults = {
        project = "P0004",
      },
    })
  end,
}
