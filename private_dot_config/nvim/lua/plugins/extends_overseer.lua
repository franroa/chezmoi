return {
  {
    lazy = false,
    "stevearc/overseer.nvim",
    config = function()
      require("overseer").setup({
        templates = {
          "builtin",
          "k8s.skaffold",
          -- "alloy.alloy_e2e_test",
          "taskfile.vars",
          "taskfile.task",
          "ansible.playbook",
          "terraform.apply_target",
          "docker.up",
          "docker.up-build",
          "docker.logs-alloy",
          "docker.logs-app",
          "ssh.tunnel",
          "gitlab.run_job",
          -- "terraform.plan",
          -- "terraform.plan_grep",
          -- "terraform.destroy",
          -- "terraform.apply",
          -- "db.start_on_kubernetes",
          "dotnet.clear_nuget_cache",
          "dotnet.push_locally",
          "dotnet.pack_nugets",
          "dotnet.migrations_create",
          "dotnet.migrations_delete",
          "dotnet.update_db",
          "dotnet.reapply_TEST_migration",
          "dotnet.run",
          "dotnet.build",
          "dotnet.clean",
          "dotnet.restore",
          "dotnet.start_db",
        },
        component_aliases = {
          default_neotest = {
            "on_output_summarize",
            "on_exit_set_status",
            "on_complete_notify",
            "on_complete_dispose",
            -- { "wait_for_it_if_exists", task_names = {
            --   "Build .NET App",
            -- } },
          },
        },
        dap = false, -- TODO: make is to false and add it later manually
        task_list = {
          bindings = {
            ["<S-l>"] = "IncreaseDetail",
            ["<S-h>"] = "DecreaseDetail",
            ["<S-k>"] = "ScrollOutputUp",
            ["<S-j>"] = "ScrollOutputDown",
          },
        },
        strategies = {
          overseer = {
            components = function(run_spec)
              return {
                {
                  "dependencies",
                  task_names = {
                    { "shell", cmd = "sleep 4" },
                  },
                },
                "default_neotest",
              }
            end,
          },
        },
      })
    end,
    opts = {},
    keys = {
      {
        "<leader>oL",
        function()
          local overseer = require("overseer")
          local tasks = overseer.list_tasks({ recent_first = true })
          if vim.tbl_isempty(tasks) then
            vim.notify("No tasks found", vim.log.levels.WARN)
          else
            overseer.run_action(tasks[1], "restart")
            overseer.run_action(tasks[1], "open float")
          end
        end,
        desc = "Run Last",
      },
      { "<leader>ow", "<cmd>OverseerToggle<cr>", desc = "Task list" },
      { "<leader>oo", "<cmd>OverseerRun<cr>", desc = "Run task" },
      { "<leader>oq", "<cmd>OverseerQuickAction<cr>", desc = "Action recent task" },
      { "<leader>oi", "<cmd>OverseerInfo<cr>", desc = "Overseer Info" },
      { "<leader>ob", "<cmd>OverseerBuild<cr>", desc = "Task builder" },
      { "<leader>ot", "<cmd>OverseerTaskAction<cr>", desc = "Task action" },
      { "<leader>oc", "<cmd>OverseerClearCache<cr>", desc = "Clear cache" },
      -- {
      --   "<leader>oTa",
      --   function()
      --     require("overseer").run_template({ name = "Terraform Apply" })
      --   end,
      --   desc = "Terraform Apply",
      -- },
      -- {
      --   "<leader>oTp",
      --   function()
      --     require("overseer").run_template({ name = "Terraform Plan" })
      --   end,
      --   desc = "Terraform Plan",
      -- },
      -- {
      --   "<leader>oTP",
      --   function()
      --     require("overseer").run_template({ name = "Terraform Plan Grep" })
      --   end,
      --   desc = "Terraform Plan Grep",
      -- },
      -- {
      --   "<leader>oTd",
      --   function()
      --     require("overseer").run_template({ name = "Terraform Destroy" })
      --   end,
      --   desc = "Terraform Destroy",
      -- },
    },
  },
}
