return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      ---@type table<string, sidekick.context.Fn>
      context = {

        staged_files = function(ctx)
          if not ctx or not ctx.cwd then
            return false
          end

          local cmd =
            string.format("cd %s && git diff --name-only --staged 2>/dev/null || echo ''", vim.fn.shellescape(ctx.cwd))

          local handle = io.popen(cmd)
          if not handle then
            return false
          end

          local output = handle:read("*a"):gsub("\n$", "")
          handle:close()

          if output == "" then
            return false
          end

          local ret = {}
          for file in output:gmatch("[^\n]+") do
            if file ~= "" then
              table.insert(ret, "- " .. file)
            end
          end

          return #ret > 0 and table.concat(ret, "\n") or false
        end,
      },
      prompts = {
        refactor = "Please refactor {this} to be more maintainable",
        security = "Review {file} for security vulnerabilities",
        conventional_commit = "Generate a conventional commit message ONLY for the following changes:\n\n{staged_files}\n\nIf there are no files it the list, do nothing. I dont want you to search for more staged or unstaged changes\nGuidelines:\n- Use format: <type>(<scope>): <description>\n- Type: feat, fix, docs, style, refactor, perf, test, chore, ci\n- Scope: the part of codebase being changed\n- Description: clear, concise, imperative mood\n- Keep first line under 50 characters\n- Add body only if changes are complex",
        custom = function(ctx)
          return "Current file: " .. ctx.buf .. " at line " .. ctx.row
        end,
      },
    },
  },
  keys = {
    {
      "<leader>am",
      function()
        require("sidekick.cli").prompt({ name = "conventional_commit" })
      end,
      desc = "Sidekick Conventional Commit",
      mode = { "n", "v" },
    },
  },
}
