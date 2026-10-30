-- Keymaps for Taskfile targets (terraform), local helm deploys and gctui.
-- Logic lives in lua/functions/{taskfile,helm,gctui}.lua
return {
  {
    "stevearc/overseer.nvim",
    opts = {
      task_win = { border = "rounded" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          require("functions.taskfile").setup()
        end,
      })
    end,
    -- stylua: ignore
    keys = {
      { "<leader>or", function() require("functions.taskfile").restart_last() end, desc = "Restart last task" },
      { "<leader>op", function() require("functions.taskfile").pick() end, desc = "Pick Taskfile target" },
      { "<leader>oc", function() require("functions.taskfile").edit_context() end, desc = "Taskfile context (module/region/tier...)" },
      { "<leader>oC", function() require("functions.taskfile").show_context() end, desc = "Show Taskfile context" },

      { "<leader>oht", function() require("functions.helm").template() end, desc = "Template (render to buffer)" },
      { "<leader>ohl", function() require("functions.helm").lint() end, desc = "Lint" },
      { "<leader>ohd", function() require("functions.helm").diff() end, desc = "Diff against cluster" },
      { "<leader>ohi", function() require("functions.helm").deploy() end, desc = "Upgrade --install (current context)" },
      { "<leader>ohu", function() require("functions.helm").uninstall() end, desc = "Uninstall" },
      { "<leader>ohs", function() require("functions.helm").status() end, desc = "Status + pods" },
      { "<leader>ohD", function() require("functions.helm").deps() end, desc = "Dependency update" },
      { "<leader>ohv", function() require("functions.helm").values() end, desc = "Values to apply (tf-rendered or file)" },
      { "<leader>ohV", function() require("functions.helm").deployed_values() end, desc = "Values deployed in cluster" },
      { "<leader>ohc", function() require("functions.helm").configure() end, desc = "Reconfigure / re-plan helm_release" },

      { "<leader>ogg", function() require("functions.gctui").open() end, desc = "gctui (local)" },
      { "<leader>ogr", function() require("functions.gctui").open({ "--remote" }) end, desc = "gctui (remote)" },
      { "<leader>ogm", function() require("functions.gctui").open({ "--mrs" }) end, desc = "gctui merge requests" },
      { "<leader>ogc", function() require("functions.gctui").open({ "--config" }) end, desc = "gctui config" },
      { "<leader>ogj", function() require("functions.gctui").run_job() end, desc = "Run job under cursor" },
      { "<leader>ogp", function() require("functions.gctui").run_pipeline() end, desc = "Run local pipeline" },
      { "<leader>oga", function() require("functions.gctui").assemble() end, desc = "Assemble pipeline" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>ol", group = "Taskfile targets (UPPER = -target)" },
        { "<leader>oh", group = "Helm (local chart)" },
        { "<leader>og", group = "gctui (pipelines)" },
      },
    },
  },
}
