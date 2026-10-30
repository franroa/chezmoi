-- Taskfile runner: dynamic keymaps for the targets of the repo's root Taskfile.
--
--   <leader>ol<letter>   run the target for the whole module
--   <leader>ol<LETTER>   run the target with -target=<terraform block under cursor>
--
-- The required vars (MODULE, REGION, TIER, SECTOR/DOMAIN, ENVIRONMENT, ...) and
-- their allowed values are read from the Taskfile's `requires.vars` enums. The
-- selected values are persisted per repository, MODULE is inferred from the
-- buffer path (terraform/<module>/...) and EXEC_LOCAL=true is passed when the
-- Taskfile declares it, so terraform/helm providers authenticate with az cli.
local M = {}

local PREFIX = "<leader>ol"
local TARGETABLE = { "plan", "apply", "destroy", "refresh", "import" }
local TASKFILES = { "Taskfile.yaml", "Taskfile.yml", "taskfile.yaml", "taskfile.yml" }
local STATE_FILE = vim.fn.stdpath("state") .. "/taskfile_context.json"

local cache = {} -- root -> { tasks, vars, uses_target_var }

local function task_bin()
  return vim.fn.executable("go-task") == 1 and "go-task" or "task"
end

---Directory containing the closest root Taskfile above the buffer (or cwd).
function M.root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  local start = (name ~= "" and vim.fn.filereadable(name) == 1) and vim.fs.dirname(name) or vim.fn.getcwd()
  local found = vim.fs.find(TASKFILES, { path = start, upward = true, limit = 1 })[1]
  return found and vim.fs.dirname(found) or nil, found
end

-- Parse `- name: X` / `enum: [...]` pairs and `X: '{{ .X | default "y" }}'` defaults.
local function parse_vars(taskfile)
  local vars, order = {}, {}
  local text = table.concat(vim.fn.readfile(taskfile), "\n")
  local current
  for line in text:gmatch("[^\n]+") do
    local name = line:match("^%s*%-%s*name:%s*['\"]?([%w_]+)")
    if name then
      current = name
      if not vars[name] then
        vars[name] = {}
        table.insert(order, name)
      end
    else
      local enum = line:match("^%s*enum:%s*%[(.*)%]")
      if enum and current then
        vars[current].enum = vim.tbl_map(function(v)
          return vim.trim(v):gsub("^['\"]", ""):gsub("['\"]$", "")
        end, vim.split(enum, ","))
      elseif not line:match("^%s*%-") and not line:match("^%s*enum:") then
        current = nil
      end
    end
    local var, default = line:match("^  ([%w_]+):%s*['\"]{{%s*%.[%w_]+%s*|%s*default%s*\"?([^\"%s}]*)")
    if var then
      if not vars[var] then
        vars[var] = {}
        table.insert(order, var)
      end
      vars[var].default = default
    end
  end
  return vars, order
end

-- -target goes through TF_CLI_ARGS when the Taskfiles forward it (it only reaches
-- plan/apply). {{ .TARGET }} is the fallback: it is templated into TF_ARGS,
-- which some Taskfiles also hand to `terraform init`, where -target is invalid.
local function forwards_cli_args(root)
  for _, f in ipairs(vim.fn.glob(root .. "/[Tt]askfile*.y*ml", false, true)) do
    if table.concat(vim.fn.readfile(f), "\n"):find("%.TF_CLI_ARGS") then
      return true
    end
  end
  return false
end

local function load(root, taskfile)
  if cache[root] then
    return cache[root]
  end
  local res = vim.system({ task_bin(), "--list-all", "--json" }, { cwd = root, text = true }):wait()
  local tasks = {}
  local ok, decoded = pcall(vim.json.decode, res.stdout or "")
  if ok and decoded and decoded.tasks then
    for _, t in ipairs(decoded.tasks) do
      -- only the root Taskfile's own targets: the included `terraform:*` ones skip the `check` guard
      if t.location and t.location.taskfile == taskfile then
        table.insert(tasks, { name = t.name, desc = t.desc ~= "" and t.desc or nil })
      end
    end
  end
  local vars, order = parse_vars(taskfile)
  cache[root] = { tasks = tasks, vars = vars, order = order, cli_args = forwards_cli_args(root) }
  return cache[root]
end

-- ── persisted context ─────────────────────────────────────────────────────────

local function read_state()
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(STATE_FILE), "\n"))
  end)
  return ok and type(data) == "table" and data or {}
end

local function write_state(state)
  vim.fn.mkdir(vim.fs.dirname(STATE_FILE), "p")
  vim.fn.writefile({ vim.json.encode(state) }, STATE_FILE)
end

---Module inferred from the buffer path: <root>/terraform/<module>/...
local function module_from_buffer(root, bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if not vim.startswith(name, root .. "/") then
    return nil
  end
  return name:sub(#root + 2):match("^terraform/([^/]+)/")
end

---Resolved var values for a root: stored > inferred module > Taskfile default.
function M.context(root, bufnr)
  local info = cache[root]
  local stored = read_state()[root] or {}
  local ctx = {}
  for _, name in ipairs(info.order) do
    local spec = info.vars[name]
    if spec.enum then
      ctx[name] = stored[name] or spec.default
    end
  end
  local mod = module_from_buffer(root, bufnr)
  local mod_spec = info.vars.MODULE
  if mod and mod_spec and (not mod_spec.enum or vim.tbl_contains(mod_spec.enum, mod)) then
    ctx.MODULE = mod
  end
  if info.vars.EXEC_LOCAL then
    ctx.EXEC_LOCAL = "true"
  end
  return ctx
end

local function context_line(ctx)
  local parts = {}
  for k, v in vim.spairs(ctx) do
    table.insert(parts, k .. "=" .. v)
  end
  return table.concat(parts, " ")
end

---Root and resolved context for the buffer's Taskfile (nil when there is none).
function M.resolve(bufnr)
  local root, taskfile = M.root(bufnr)
  if not root then
    return nil
  end
  load(root, taskfile)
  return root, M.context(root, bufnr)
end

---Prompt for every enum var of the Taskfile, one after another.
function M.edit_context()
  local root, taskfile = M.root()
  if not root then
    return vim.notify("No Taskfile found", vim.log.levels.WARN)
  end
  local info = load(root, taskfile)
  local current = M.context(root)
  local names = vim.tbl_filter(function(n)
    return info.vars[n].enum ~= nil
  end, info.order)
  local state = read_state()
  state[root] = state[root] or {}

  local function step(i)
    if i > #names then
      write_state(state)
      return vim.notify(context_line(M.context(root)), vim.log.levels.INFO, { title = "Taskfile context" })
    end
    local name = names[i]
    local choices = vim.deepcopy(info.vars[name].enum)
    table.sort(choices, function(a, b)
      return a == current[name] and b ~= current[name]
    end)
    vim.ui.select(choices, { prompt = name .. " (current: " .. tostring(current[name]) .. ")" }, function(choice)
      if not choice then
        return
      end
      state[root][name] = choice
      step(i + 1)
    end)
  end
  step(1)
end

function M.show_context()
  local root, taskfile = M.root()
  if not root then
    return vim.notify("No Taskfile found", vim.log.levels.WARN)
  end
  load(root, taskfile)
  vim.notify(root .. "\n" .. context_line(M.context(root)), vim.log.levels.INFO, { title = "Taskfile context" })
end

-- ── terraform address under cursor ────────────────────────────────────────────

---Top-level block under the cursor as (kind, label1, label2), e.g.
---("resource", "helm_release", "loki"). Plain text scan (terraform fmt keeps
---top-level blocks at column 0), so it works without the hcl treesitter parser.
function M.block_under_cursor()
  local lnum = vim.fn.line(".")
  local lines = vim.api.nvim_buf_get_lines(0, 0, lnum, false)
  for i = lnum, 1, -1 do
    local line = lines[i]
    if i < lnum and line:match("^}") then
      return nil
    end
    local kind, a, b = line:match('^(%a+)%s+"([^"]+)"%s*"?([^"%s{]*)"?%s*{')
    if kind then
      return kind, a, b ~= "" and b or nil
    elseif line:match("^%a+%s*{") then
      return nil
    end
  end
end

-- Address of the top-level block under the cursor: resource / data / module.
local function block_address()
  local kind, a, b = M.block_under_cursor()
  if kind == "resource" and b then
    return a .. "." .. b
  elseif kind == "data" and b then
    return "data." .. a .. "." .. b
  elseif kind == "module" then
    return "module." .. a
  end
end

function M.module_dir(root, ctx)
  return root .. "/terraform/" .. (ctx.MODULE or "")
end

-- When the buffer is inside a local child module, find the `module "x"` call in
-- the root module whose `source` points to that directory.
local function module_prefix(module_dir, file)
  local dir = vim.fs.dirname(file)
  if dir == module_dir then
    return ""
  end
  for _, tf in ipairs(vim.fn.glob(module_dir .. "/*.tf", false, true)) do
    local current
    for _, line in ipairs(vim.fn.readfile(tf)) do
      current = line:match('^module%s+"([^"]+)"') or current
      local source = line:match('^%s*source%s*=%s*"(%.[^"]*)"')
      if current and source and vim.fs.normalize(module_dir .. "/" .. source) == dir then
        return "module." .. current .. "."
      end
    end
  end
  vim.notify("Could not resolve the module call for " .. dir .. ", targeting without prefix", vim.log.levels.WARN)
  return ""
end

function M.target_under_cursor(root, ctx)
  local addr = block_address()
  if not addr then
    return nil
  end
  local module_dir = M.module_dir(root, ctx)
  return module_prefix(module_dir, vim.api.nvim_buf_get_name(0)) .. addr
end

-- ── running ───────────────────────────────────────────────────────────────────

local function open(task, direction)
  if not task then
    return
  end
  if direction == "list" then
    -- task list window (:OverseerOpen); no-op when it is already open, keeps focus in the buffer
    require("overseer").open({ enter = false, focus_task_id = task.id })
  else
    require("overseer").run_action(task, "open " .. direction)
  end
end

---@param name string Taskfile target
---@param opts? { target?: boolean, cli_args?: string, open?: "float"|"list"|false, on_complete?: fun(task: overseer.Task, status: string) }
---@return overseer.Task|nil
function M.run(name, opts)
  opts = opts or {}
  local root, taskfile = M.root()
  if not root then
    return vim.notify("No Taskfile found", vim.log.levels.WARN)
  end
  local info = load(root, taskfile)
  local ctx = M.context(root)

  local cmd = { "env", "-u", "GIT_DIR", "-u", "GIT_WORK_TREE", task_bin(), name }
  for k, v in vim.spairs(ctx) do
    table.insert(cmd, k .. "=" .. v)
  end

  local title = name
  local cli_args = opts.cli_args and { opts.cli_args } or {}
  if opts.target then
    local target = M.target_under_cursor(root, ctx)
    if not target then
      return vim.notify("Cursor is not inside a resource/data/module block", vim.log.levels.WARN)
    end
    if info.cli_args then
      table.insert(cli_args, 1, "-target=" .. target)
    else
      table.insert(cmd, "TARGET=" .. target)
    end
    title = name .. " → " .. target
  end
  if #cli_args > 0 then
    table.insert(cmd, "TF_CLI_ARGS=" .. table.concat(cli_args, " "))
  end

  vim.cmd("silent! wall")
  local task = require("overseer").new_task({
    name = string.format("task %s [%s]", title, context_line(ctx)),
    cmd = cmd,
    cwd = root,
    components = { "default", "unique" },
  })
  if opts.on_complete then
    task:subscribe("on_complete", function(t, status)
      vim.schedule(function()
        opts.on_complete(t, status)
      end)
      return true
    end)
  end
  task:start()
  if opts.open ~= false then
    open(task, opts.open or "float")
  end
  return task
end

---Picker with every target of the Taskfile (including included namespaces).
function M.pick()
  local root, taskfile = M.root()
  if not root then
    return vim.notify("No Taskfile found", vim.log.levels.WARN)
  end
  load(root, taskfile)
  local res = vim.system({ task_bin(), "--list-all", "--json" }, { cwd = root, text = true }):wait()
  local ok, decoded = pcall(vim.json.decode, res.stdout or "")
  if not ok then
    return vim.notify("task --list-all failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
  end
  vim.ui.select(decoded.tasks, {
    prompt = "Task (" .. context_line(M.context(root)) .. ")",
    format_item = function(t)
      return t.desc ~= "" and (t.name .. "  — " .. t.desc) or t.name
    end,
  }, function(t)
    if t then
      M.run(t.name)
    end
  end)
end

function M.restart_last()
  local overseer = require("overseer")
  local task = overseer.list_tasks({ sort = require("overseer.task_list").sort_newest_first })[1]
  if not task then
    return vim.notify("No tasks found", vim.log.levels.WARN)
  end
  overseer.run_action(task, "restart")
  open(task, "float")
end

-- ── dynamic keymaps ───────────────────────────────────────────────────────────

-- Assign a key per target: first letter, then the next free letter of the name.
local function assign_keys(tasks)
  local used, keys = {}, {}
  local sorted = vim.deepcopy(tasks)
  table.sort(sorted, function(a, b)
    return #a.name < #b.name
  end)
  for _, t in ipairs(sorted) do
    for ch in t.name:lower():gmatch("%a") do
      if not used[ch] then
        used[ch] = true
        keys[t.name] = ch
        break
      end
    end
  end
  return keys
end

---Buffer-local keymaps for the Taskfile of the buffer's repository.
function M.attach(bufnr)
  if vim.b[bufnr].taskfile_attached or vim.bo[bufnr].buftype ~= "" then
    return
  end
  local root, taskfile = M.root(bufnr)
  if not root then
    return
  end
  local info = load(root, taskfile)
  local keys = assign_keys(info.tasks)
  local is_tf = vim.bo[bufnr].filetype == "terraform" or vim.bo[bufnr].filetype == "hcl"
  local lhs_list = {}

  for _, t in ipairs(info.tasks) do
    local ch = keys[t.name]
    if ch then
      local desc = t.name .. (t.desc and (": " .. t.desc) or "")
      vim.keymap.set("n", PREFIX .. ch, function()
        M.run(t.name, { open = "list" })
      end, { buffer = bufnr, desc = desc })
      table.insert(lhs_list, PREFIX .. ch)
      if is_tf and vim.tbl_contains(TARGETABLE, t.name) then
        vim.keymap.set("n", PREFIX .. ch:upper(), function()
          M.run(t.name, { target = true, open = "list" })
        end, { buffer = bufnr, desc = t.name .. " -target=<block under cursor>" })
        table.insert(lhs_list, PREFIX .. ch:upper())
      end
    end
  end
  vim.b[bufnr].taskfile_attached = lhs_list
end

function M.reload()
  cache = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].taskfile_attached then
      for _, lhs in ipairs(vim.b[buf].taskfile_attached) do
        pcall(vim.keymap.del, "n", lhs, { buffer = buf })
      end
      vim.b[buf].taskfile_attached = nil
      if vim.api.nvim_buf_is_loaded(buf) then
        M.attach(buf)
      end
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("taskfile_keymaps", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      M.attach(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = { "Taskfile*.yaml", "Taskfile*.yml", "taskfile*.yaml", "taskfile*.yml" },
    callback = M.reload,
  })
  M.attach(vim.api.nvim_get_current_buf())
end

return M
