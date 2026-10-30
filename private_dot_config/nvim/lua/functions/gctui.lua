-- gctui (GitLab pipeline TUI) integration for developing pipelines: the TUI in
-- a float, plus headless runs of the job under cursor / the whole local pipeline.
local M = {}

-- top-level keys of a CI file that are not jobs
local NOT_JOBS = { "stages", "variables", "workflow", "default", "include", "spec", "image", "services", "cache" }

---Directory with the .gitlab-ci.yml that owns the current buffer.
function M.root()
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local found = vim.fs.find(".gitlab-ci.yml", { path = start, upward = true, limit = 1 })[1]
  return found and vim.fs.dirname(found) or nil
end

---Open the TUI in a float. `args` are extra gctui flags (--remote, --mrs, ...).
function M.open(args)
  local root = M.root()
  if not root then
    return vim.notify("No .gitlab-ci.yml found", vim.log.levels.WARN)
  end
  vim.cmd("silent! wall")
  local cmd = vim.list_extend({ "gctui" }, args or {})
  table.insert(cmd, root)
  Snacks.terminal(cmd, {
    cwd = root,
    win = { position = "float", width = 0.95, height = 0.95, border = "rounded" },
  })
end

---Job whose top-level key encloses the cursor line in a CI yaml buffer.
function M.job_under_cursor()
  local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line("."), false)
  for i = #lines, 1, -1 do
    local key = lines[i]:match("^([%w_.][^#]-):%s*$") or lines[i]:match("^([%w_.-]+):")
    if key then
      if key:sub(1, 1) == "." or vim.tbl_contains(NOT_JOBS, key) then
        return nil
      end
      return key
    end
  end
end

local function run(name, cmd, cwd)
  vim.cmd("silent! wall")
  local task = require("overseer").new_task({ name = name, cmd = cmd, cwd = cwd, components = { "default", "unique" } })
  task:start()
  require("overseer").run_action(task, "open float")
end

---Run the job under cursor headless (gctui run <job>).
function M.run_job()
  local root = M.root()
  local job = M.job_under_cursor()
  if not root or not job then
    return vim.notify("Cursor is not inside a GitLab CI job", vim.log.levels.WARN)
  end
  run("gctui run " .. job, { "gctui", "run", job, root }, root)
end

---Run the whole local pipeline headless.
function M.run_pipeline()
  local root = M.root()
  if not root then
    return vim.notify("No .gitlab-ci.yml found", vim.log.levels.WARN)
  end
  run("gctui run-pipeline " .. vim.fs.basename(root), { "gctui", "run-pipeline", root }, root)
end

---Headless pipeline assembly (writes the assembled pipeline, see `gctui assemble -h`).
function M.assemble()
  local root = M.root()
  if not root then
    return vim.notify("No .gitlab-ci.yml found", vim.log.levels.WARN)
  end
  run("gctui assemble " .. vim.fs.basename(root), { "gctui", "assemble", root }, root)
end

return M
