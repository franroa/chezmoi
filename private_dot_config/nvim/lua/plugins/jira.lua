-- return {
--   "emrearmagan/atlas.nvim",
--   -- "atlas.vim",
--   -- dir = "/home/froa/Projects/fran/atlas.nvim",
--   dependencies = {
--     "MeanderingProgrammer/render-markdown.nvim", -- optional but recommended (Jira)
--     "sindrets/diffview.nvim", -- optional (PullRequest diff)
--     "esmuellert/codediff.nvim", -- optional (PullRequest diff alternative)
--   },
--   config = function()
--     require("atlas").setup({
--       pulls = {
--         providers = {
--           bitbucket = {}, -- See configuration below
--           github = {}, -- See configuration below
--         },
--       },
--       issues = {
--         providers = {
--           jira = {
--             base_url = vim.env.JIRA_BASE_URL,
--             email = vim.env.JIRA_EMAIL,
--             --- See: https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/
--             token = vim.env.JIRA_TOKEN,
--           }, -- See configuration below
--         },
--       },
--     })
--   end,
-- }

return {
  "letieu/jira.nvim",
  opts = {
    -- Your setup options...
    -- Jira settings
    jira = {
      api_version = "3", -- API version: "2" or "3" (default: "3")
      limit = 200, -- Global limit of tasks per view (default: 200)
      logging = false, -- Enable HTTP request/response logging (default: false)
    },

    active_sprint_query = "project = '%s' AND sprint in openSprints() ORDER BY Rank ASC",

    -- Saved JQL queries for the JQL tab
    -- Use %s as a placeholder for the project key
    queries = {
      ["My Tasks"] = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
      ["Yesterday"] = "assignee = currentUser() AND statusCategory != Done AND updated >= startOfDay(-1) AND updated < startOfDay() ORDER BY updated DESC",
    },

    -- Project-specific overrides
    -- Still think about this config, maybe not good enough
    projects = {
      ["DEV"] = {
        story_point_field = "customfield_10035", -- Custom field ID for story points
        custom_fields = { -- Custom field to display in markdown view
          { key = "customfield_10016", label = "Acceptance Criteria" },
        },
      },
    },
  },
}
