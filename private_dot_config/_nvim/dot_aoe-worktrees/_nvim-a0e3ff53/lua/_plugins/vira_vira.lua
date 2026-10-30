vim.g.vira_config_file_servers = "/home/francisco/.config/vira/vira_servers.json"
vim.g.vira_config_file_projects = "/home/francisco/.config/vira/vira_projects.json"
vim.g.is_comming_from_vira = false

function get_env_from_project_file(var_name)
  local root, method = require("project_nvim.project").get_project_root()
  -- TODO: check if .nvim_project.env file exists and if the given variable is in the file
  return vim.fn.system(". " .. root .. "/" .. ".nvim_project.env 2>/dev/null && echo -n $" .. var_name)
end

function viraCmd(command)
  local viraProject = get_env_from_project_file("vira_project")
  if viraProject == "" then
    vim.notify("Using vira default project")
  end

  vim.cmd("ViraLoadProject " .. viraProject)
  setViraIssueGlobal()
  vim.cmd(command)
end

function setViraIssueGlobal()
  if require("functions.utils").is_a_git_repository() then
    vim.notify("Jira Issue: " .. vim.g.VIRA_ISSUE .. " - " .. vim.g.VIRA_ISSUE_DESCRIPTION)
    vim.g.vira_active_issue = vim.g.VIRA_ISSUE
  else
    vim.g.vira_active_issue = nil
  end
end

function is_a_new_vira_chosen()
  return vim.g.VIRA_ISSUE ~= vim.g.vira_active_issue
end

function UpdateGitBranchFromViraIssue()
  local vira_git_branch = get_env_from_project_file("git_branch")
  if vira_git_branch == "" then
    vim.notify("Defaulting to main branch")
    vira_git_branch = "main"
  end
  OpenOrCreateTerminal({
    instruction = "~/.config/nvim/update_git_branch.sh " .. vim.g.vira_active_issue .. " " .. vira_git_branch,
    name = "Update Git Branch",
    direction = "horizontal",
  })
end

function set_vira_issue_from_branch()
  local git_path = require("functions.utils").get_git_path()

  vim.g.VIRA_ISSUE = vim.fn.system(
    "echo -n $(cut -d '_' -f1 <<< $(cut -d '/' -f2 <<<$(git --git-dir=" .. git_path .. "/.git branch --show-current)))"
  )

  if is_a_new_vira_chosen() then
    vim.g.VIRA_ISSUE_DESCRIPTION = vim.fn.system(
      "echo -n $(cut -d '_' -f 3- <<< $(cut -d '/' -f2 <<<$(git --git-dir="
        .. git_path
        .. "/.git branch --show-current)) --output-delimiter=' ')"
    )
    setViraIssueGlobal()
  end
end

return {
  -- add symbols-outline
  {
    lazy = true,
    cmd = "ViraLoadProject",
    "n0v1c3/vira",
    dependencies = {
      -- which key integration
      {
        "folke/which-key.nvim",
        opts = function(_, opts)
          if require("lazyvim.util").has("noice.nvim") then
            opts.spec["<leader>v"] = { name = "+vira" }
          end
        end,
      },
    },
    keys = {
      {
        "<leader>ve",
        function()
          viraCmd("ViraEditComment")
        end,
        desc = "Edit comment",
      },
      {
        "<leader>vr",
        function()
          viraCmd("ViraReport")
        end,
        desc = "Issue Report",
      },
      {
        "<leader>vc",
        function()
          viraCmd("ViraComment")
        end,
        desc = "Add comment to issue",
      },
      {
        "<leader>vi",
        function()
          viraCmd("ViraIssues")
        end,
        desc = "All issues",
      },
      {
        "<leader>vn",
        function()
          viraCmd("ViraIssue")
        end,
        desc = "New issue",
      },
      {
        "<leader>vj",
        function()
          set_vira_issue_from_branch()
        end,
        desc = "Set the jira issue from branch",
      },
      -- {
      --   "<leader>vb",
      --   function()
      --     setViraIssueGlobal()
      --     OpenOrCreateTerminal({
      --       instruction = "~/.config/nvim/update_git_branch.sh " .. vim.g.vira_active_issue,
      --       name = "Update Git Branch",
      --     })
      --   end,
      --   desc = "Create a branch from Jira issue",
      -- },
    },
  },
}
