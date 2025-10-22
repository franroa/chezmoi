vim.cmd(":0")
vim.cmd("startinsert!")
vim.bo.commentstring = "; %s"
vim.treesitter.language.register("markdown", "gitcommit")
-- Git commit Jira Ticket
--
if vim.g.vira_active_issue == "None" then
  vim.notify("No Jira Ticket defined", "ERROR")
end

local issue = ""
if vim.g.VIRA_ISSUE == nil then
  issue = "None"
else
  issue = vim.g.VIRA_ISSUE
end

local context = {
  COMMIT_TITLE = issue,
  BRANCH_NAME = vim.fn.system("echo -n $(git branch --show-current)"),
  AUTHOR = "Francisco Roa Prieto",
  JIRA_TICKET = issue,
}

vim.fn.setline(1, vim.fn.substitute(vim.fn.getline(1), "${COMMIT_TITLE}", context["COMMIT_TITLE"], "g"))
vim.fn.setline(2, vim.fn.substitute(vim.fn.getline(2), "${AUTHOR}", context["AUTHOR"], "g"))
vim.fn.setline(3, vim.fn.substitute(vim.fn.getline(3), "${BRANCH_NAME}", context["BRANCH_NAME"], "g"))
vim.fn.setline(4, vim.fn.substitute(vim.fn.getline(4), "${JIRA_TICKET}", context["JIRA_TICKET"], "g"))

-- local lnum = vim.fn.nextnonblank(1)
-- while lnum and lnum < vim.fn.line("$") do
-- vim.fn.setline(lnum, vim.fn.substitute(vim.fn.getline(lnum), "${\\w*}", context["\\=vim.fn.submatch(0)"], "g"))
-- vim.fn.setline(lnum, vim.fn.substitute(vim.fn.getline(lnum), "${COMMIT_TITLE}", context["COMMIT_TITLE"], "g"))
-- vim.fn.setline(lnum, vim.fn.substitute(vim.fn.getline(lnum), "${BRANCH_NAME}", context["BRANCH_NAME"], "g"))
--  vim.fn.setline(lnum, vim.fn.substitute(vim.fn.getline(lnum), "${AUTHOR}", context["AUTHOR"], "g"))
--  vim.fn.setline(lnum, vim.fn.substitute(vim.fn.getline(lnum), "${JIRA_TICKET}", context["JIRA_TICKET"], "g"))
-- lnum = vim.fn.nextnonblank(lnum + 1)
-- end
