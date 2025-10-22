return {
  {
    "isakbm/gitgraph.nvim",
    dependencies = { "sindrets/diffview.nvim" },
    ---@type I.GGConfig
    opts = {
      symbols = {
        -- merge_commit = "",
        -- commit = "",
        -- merge_commit_end = "",
        -- commit_end = "",

        -- Advanced symbols
        -- GVER = "",
        -- GHOR = "",
        -- GCLD = "",
        -- GCRD = "╭",
        -- GCLU = "",
        -- GCRU = "",
        -- GLRU = "",
        -- GLRD = "",
        -- GLUD = "",
        -- GRUD = "",
        -- GFORKU = "",
        -- GFORKD = "",
        -- GRUDCD = "",
        -- GRUDCU = "",
        -- GLUDCD = "",
        -- GLUDCU = "",
        -- GLRDCL = "",
        -- GLRDCR = "",
        -- GLRUCL = "",
        -- GLRUCR = "",
      },
      hooks = {
        -- Check diff of a commit
        on_select_commit = function(commit)
          vim.notify("DiffviewOpen " .. commit.hash .. "^!")
          vim.cmd(":DiffviewOpen " .. commit.hash .. "^!")
        end,
        -- Check diff from commit a -> commit b
        on_select_range_commit = function(from, to)
          vim.notify("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
          vim.cmd(":DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
        end,
      },
      format = {
        timestamp = "%H:%M:%S %d-%m-%Y",
        fields = { "hash", "timestamp", "author", "branch_name", "tag" },
      },
    },
    init = function()
      vim.keymap.set("n", "<leader>AA", function()
        require("gitgraph").draw({}, { all = true, max_count = 5000 })
      end, { desc = "new git graph" })
      vim.keymap.set("n", "<leader>Aa", function()
        local line1 = vim.fn.getpos("v")[2]
        local line2 = vim.fn.getcurpos()[2]
        -- print("first: " .. line1 .. "second: " .. line2)
        local range = "-L" .. line1 .. "," .. line2 .. ":<TODO: git-rooted path>"
        require("neogit").action("log", "log_current", { "--graph" })()
      end, { desc = "new git graph" })
    end,
  },
}
