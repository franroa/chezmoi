return {
  {
    "emmanueltouzery/agitator.nvim",
    keys = {
      {
        "<leader>ga",
        function()
          local commit_sha = require("agitator").git_blame_commit_for_line()
          vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha)
        end,
        desc = "Blame with agitator and diffview",
      },
      {
        "<leader>gS",
        function()
          require("agitator").search_git_branch()
        end,
        desc = "Search git branch",
      },
      {
        "<leader>gt",
        function()
          require("agitator").git_time_machine({ use_current_win = true })
        end,
        desc = "Git Time Machine",
      },
      {
        "<leader>gf",
        function()
          require("agitator").open_file_git_branch()
        end,
        desc = "Open file git branch",
      },
      -- {
      --   "<leader>gB",
      --   function()
      --     require("agitator").git_blame_toggle({
      --       formatter = function(r)
      --         return r.author .. " => " .. r.summary
      --       end,
      --     })
      --   end,
      --
      --   desc = "Git Blame all lines",
      -- },
    },
  },
}
