-- Local helm workflow. The release comes from one of two sources:
--   * a `resource "helm_release"` block under the cursor: a targeted `task plan`
--     is run and chart, repository, version, namespace and the rendered values
--     (post templatefile()) are read from `terraform show -json` of that plan
--   * otherwise the chart of the current buffer (or one picked in the repo);
--     release, namespace and values file are prompted and remembered per chart
-- Then render, lint, diff, show values and upgrade --install into the current
-- kube context.
local M = {}

local STATE_FILE = vim.fn.stdpath("state") .. "/helm_context.json"

local tf_cache = {} -- "<root>|<address>|<context>" -> release spec

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

local function kube_context()
  local res = vim.system({ "kubectl", "config", "current-context" }, { text = true }):wait()
  return res.code == 0 and vim.trim(res.stdout) or nil
end

local function scratch(name, text, ft)
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  pcall(vim.api.nvim_buf_set_name, buf, name .. "/" .. buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n"))
  vim.bo[buf].filetype = ft or "yaml"
end

-- ── local chart source ────────────────────────────────────────────────────────

local function chart_name(chart)
  for _, line in ipairs(vim.fn.readfile(chart .. "/Chart.yaml")) do
    local name = line:match("^name:%s*['\"]?([^'\"%s]+)")
    if name then
      return name
    end
  end
  return vim.fs.basename(chart)
end

---Chart dir of the buffer, or pick one of the charts in the repository.
local function with_chart(cb)
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local found = vim.fs.find("Chart.yaml", { path = start, upward = true, limit = 1 })[1]
  if found then
    return cb(vim.fs.dirname(found))
  end
  local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
  local charts = vim.tbl_map(
    vim.fs.dirname,
    vim.fs.find("Chart.yaml", {
      path = root,
      limit = math.huge,
      skip = function(dir)
        return not vim.tbl_contains({ ".git", ".terraform", "node_modules", ".aoe-worktrees", "charts", ".charts" }, dir)
      end,
    })
  )
  if #charts == 0 then
    return vim.notify(
      "No Chart.yaml found (in a .tf file, put the cursor inside a helm_release block)",
      vim.log.levels.WARN
    )
  elseif #charts == 1 then
    return cb(charts[1])
  end
  vim.ui.select(charts, {
    prompt = "Chart",
    format_item = function(c)
      return vim.fn.fnamemodify(c, ":~:.")
    end,
  }, function(c)
    if c then
      cb(c)
    end
  end)
end

-- values*.yaml next to the chart and in sibling releases/ or values/ dirs
local function values_candidates(chart)
  local files = {}
  for _, dir in ipairs({ chart, vim.fs.dirname(chart) .. "/releases", chart .. "/values", vim.fs.dirname(chart) .. "/values" }) do
    for _, f in ipairs(vim.fn.glob(dir .. "/*.y*ml", false, true)) do
      local base = vim.fs.basename(f)
      if base ~= "Chart.yaml" and base ~= "Chart.lock" and not vim.tbl_contains(files, f) then
        table.insert(files, f)
      end
    end
  end
  return files
end

---Release spec for a local chart; prompts the first time (or when `reconfigure`).
local function with_local_release(chart, reconfigure, cb)
  local function spec(cfg)
    return {
      label = cfg.release,
      release = cfg.release,
      namespace = cfg.namespace,
      chart = { chart },
      local_chart = chart,
      values = cfg.values,
      cwd = chart,
    }
  end
  local state = read_state()
  local saved = state[chart]
  if saved and not reconfigure then
    return cb(spec(saved))
  end
  local default_name = saved and saved.release or chart_name(chart)
  vim.ui.input({ prompt = "Release name: ", default = default_name }, function(release)
    if not release or release == "" then
      return
    end
    vim.ui.input({ prompt = "Namespace: ", default = saved and saved.namespace or release }, function(namespace)
      if not namespace or namespace == "" then
        return
      end
      local choices = { "(chart defaults only)" }
      vim.list_extend(choices, values_candidates(chart))
      vim.ui.select(choices, {
        prompt = "Extra values file",
        format_item = function(f)
          return vim.fn.fnamemodify(f, ":~:.")
        end,
      }, function(values)
        if not values then
          return
        end
        local cfg = { release = release, namespace = namespace, values = values ~= choices[1] and { values } or {} }
        state[chart] = cfg
        write_state(state)
        cb(spec(cfg))
      end)
    end)
  end)
end

-- ── terraform helm_release source ─────────────────────────────────────────────

-- Chart reference args for helm from the planned helm_release attributes.
local function chart_args(after, module_dir)
  local repo, chart = after.repository or "", after.chart
  local args
  if repo:match("^oci://") then
    args = { repo:gsub("/$", "") .. "/" .. chart }
  elseif repo:match("^https?://") then
    args = { chart, "--repo", repo }
  elseif repo ~= "" then
    args = { vim.fs.normalize(module_dir .. "/" .. repo .. "/" .. chart) }
  else
    args = { chart:match("^[/.]") and vim.fs.normalize(module_dir .. "/" .. chart) or chart }
  end
  if after.version and after.version ~= "" then
    vim.list_extend(args, { "--version", after.version })
  end
  return args
end

local function close_task_float(task)
  local bufnr = task:get_bufnr()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr and vim.api.nvim_win_get_config(win).relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

-- Read the planned helm_release from the plan file into a release spec.
local function extract(planfile, module_dir, address)
  local res = vim.system({ "terraform", "show", "-json", planfile }, { cwd = module_dir, text = true }):wait()
  os.remove(planfile) -- contains a state snapshot
  if res.code ~= 0 then
    return nil, "terraform show failed:\n" .. (res.stderr or "")
  end
  local ok, plan = pcall(vim.json.decode, res.stdout, { luanil = { object = true, array = true } })
  if not ok then
    return nil, "could not decode the plan JSON"
  end
  for _, rc in ipairs(plan.resource_changes or {}) do
    if rc.address == address or vim.startswith(rc.address, address .. "[") then
      local after = rc.change.after
      if not after then
        return nil, rc.address .. " is planned for deletion"
      end
      local unknown = rc.change.after_unknown or {}
      if unknown.values or unknown.name or unknown.namespace then
        vim.notify(rc.address .. ": some attributes are only known after apply", vim.log.levels.WARN)
      end
      -- rendered values carry secrets: keep them in nvim's private (0700) tempdir
      local values = {}
      for _, v in ipairs(after.values or {}) do
        local f = vim.fn.tempname() .. ".values.yaml"
        vim.fn.writefile(vim.split(v, "\n"), f)
        table.insert(values, f)
      end
      return {
        label = rc.address,
        release = after.name,
        namespace = after.namespace or "default",
        chart = chart_args(after, module_dir),
        values = values,
        cwd = module_dir,
        terraform = rc.address,
      }
    end
  end
  return nil, address .. " not found in the plan"
end

---Release spec for the helm_release block under the cursor (cached per context).
local function with_tf_release(refresh, cb)
  local tf = require("functions.taskfile")
  local root, ctx = tf.resolve()
  if not root then
    return vim.notify("No Taskfile found for this terraform module", vim.log.levels.WARN)
  end
  local address = tf.target_under_cursor(root, ctx)
  local parts = {}
  for k, v in vim.spairs(ctx) do
    table.insert(parts, k .. "=" .. v)
  end
  local key = table.concat({ root, address, table.concat(parts, " ") }, "|")
  if tf_cache[key] and not refresh then
    return cb(tf_cache[key])
  end
  local planfile = vim.fn.tempname() .. ".tfplan"
  local module_dir = tf.module_dir(root, ctx)
  tf.run("plan", {
    target = true,
    cli_args = "-out=" .. planfile,
    on_complete = function(task, status)
      if status ~= "SUCCESS" then
        os.remove(planfile)
        return vim.notify("terraform plan failed, see the task output", vim.log.levels.ERROR)
      end
      local spec, err = extract(planfile, module_dir, address)
      if not spec then
        return vim.notify(err, vim.log.levels.ERROR, { title = "helm" })
      end
      tf_cache[key] = spec
      close_task_float(task)
      cb(spec)
    end,
  })
end

local function in_helm_release()
  local ft = vim.bo.filetype
  if ft ~= "terraform" and ft ~= "hcl" and not vim.api.nvim_buf_get_name(0):match("%.tf$") then
    return false
  end
  local kind, rtype = require("functions.taskfile").block_under_cursor()
  return kind == "resource" and rtype == "helm_release"
end

---Resolve the release for the current cursor/buffer and call `cb(spec)`.
local function with_source(cb, opts)
  opts = opts or {}
  if in_helm_release() then
    return with_tf_release(opts.refresh, cb)
  end
  with_chart(function(chart)
    with_local_release(chart, opts.reconfigure, cb)
  end)
end

-- ── actions ───────────────────────────────────────────────────────────────────

local function release_args(spec, ctx)
  local args = { "--namespace", spec.namespace }
  if ctx then
    vim.list_extend(args, { "--kube-context", ctx })
  end
  for _, f in ipairs(spec.values) do
    vim.list_extend(args, { "-f", f })
  end
  return args
end

local function run(name, cmd, cwd)
  vim.cmd("silent! wall")
  local task = require("overseer").new_task({ name = name, cmd = cmd, cwd = cwd, components = { "default", "unique" } })
  task:start()
  require("overseer").run_action(task, "open float")
end

local function confirm(msg)
  return vim.fn.confirm(msg, "&Yes\n&No", 2) == 1
end

---Render the chart into a scratch yaml buffer.
function M.template()
  with_source(function(spec)
    local cmd = vim.list_extend({ "helm", "template", spec.release }, spec.chart)
    table.insert(cmd, "--dependency-update")
    vim.list_extend(cmd, release_args(spec))
    vim.system(cmd, { text = true, cwd = spec.cwd }, function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          return vim.notify(res.stderr, vim.log.levels.ERROR, { title = "helm template" })
        end
        scratch("helm-template://" .. spec.release, res.stdout)
      end)
    end)
  end)
end

---Values passed to the release (rendered by terraform, or the chosen file).
function M.values()
  with_source(function(spec)
    if #spec.values == 0 then
      return vim.notify(spec.label .. " uses the chart defaults only", vim.log.levels.INFO)
    end
    local text = {}
    for _, f in ipairs(spec.values) do
      table.insert(text, table.concat(vim.fn.readfile(f), "\n"))
    end
    scratch("helm-values://" .. spec.release, table.concat(text, "\n---\n"))
  end)
end

---User-supplied values of the release currently deployed in the cluster.
function M.deployed_values()
  with_source(function(spec)
    local ctx = kube_context()
    if not ctx then
      return vim.notify("No current kube context", vim.log.levels.ERROR)
    end
    local cmd = { "helm", "get", "values", spec.release, "--namespace", spec.namespace, "--kube-context", ctx }
    vim.system(cmd, { text = true }, function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          return vim.notify(res.stderr, vim.log.levels.ERROR, { title = "helm get values" })
        end
        scratch("helm-deployed://" .. spec.release, res.stdout)
      end)
    end)
  end)
end

function M.lint()
  with_source(function(spec)
    if not spec.local_chart then
      return vim.notify("helm lint needs a local chart; use template/diff for remote charts", vim.log.levels.WARN)
    end
    local cmd = { "helm", "lint", spec.local_chart }
    for _, f in ipairs(spec.values) do
      vim.list_extend(cmd, { "-f", f })
    end
    run("helm lint " .. spec.release, cmd, spec.cwd)
  end)
end

function M.deps()
  with_chart(function(chart)
    run("helm dependency update " .. chart_name(chart), { "helm", "dependency", "update", chart }, chart)
  end)
end

function M.diff()
  with_source(function(spec)
    local ctx = kube_context()
    local cmd = vim.list_extend({ "helm", "diff", "upgrade", spec.release }, spec.chart)
    vim.list_extend(cmd, { "--allow-unreleased", "--context", "3" })
    vim.list_extend(cmd, release_args(spec, ctx))
    run(string.format("helm diff %s [%s/%s]", spec.release, ctx, spec.namespace), cmd, spec.cwd)
  end)
end

---helm upgrade --install into the current kube context.
function M.deploy()
  with_source(function(spec)
    local ctx = kube_context()
    if not ctx then
      return vim.notify("No current kube context", vim.log.levels.ERROR)
    end
    local msg = string.format("Deploy release '%s' to %s / %s?", spec.release, ctx, spec.namespace)
    if spec.terraform then
      msg = msg .. "\n(" .. spec.terraform .. " is managed by terraform: the next apply will reconcile it)"
    end
    if not confirm(msg) then
      return
    end
    local cmd = vim.list_extend({ "helm", "upgrade", "--install", spec.release }, spec.chart)
    vim.list_extend(cmd, { "--create-namespace", "--dependency-update", "--wait", "--timeout", "10m" })
    vim.list_extend(cmd, release_args(spec, ctx))
    run(string.format("helm upgrade %s [%s/%s]", spec.release, ctx, spec.namespace), cmd, spec.cwd)
  end)
end

function M.uninstall()
  with_source(function(spec)
    local ctx = kube_context()
    if not ctx or not confirm(string.format("Uninstall release '%s' from %s / %s?", spec.release, ctx, spec.namespace)) then
      return
    end
    local cmd = { "helm", "uninstall", spec.release, "--namespace", spec.namespace, "--kube-context", ctx }
    run(string.format("helm uninstall %s [%s/%s]", spec.release, ctx, spec.namespace), cmd, spec.cwd)
  end)
end

function M.status()
  with_source(function(spec)
    local ctx = kube_context()
    if not ctx then
      return vim.notify("No current kube context", vim.log.levels.ERROR)
    end
    local e = vim.fn.shellescape
    local cmd = { "sh", "-c", string.format(
      "helm status %s -n %s --kube-context %s --show-resources; kubectl --context %s -n %s get pods -l app.kubernetes.io/instance=%s",
      e(spec.release), e(spec.namespace), e(ctx), e(ctx), e(spec.namespace), e(spec.release)
    ) }
    run(string.format("helm status %s [%s/%s]", spec.release, ctx, spec.namespace), cmd, spec.cwd)
  end)
end

---Local chart: change release/namespace/values. helm_release block: re-run the plan.
function M.configure()
  with_source(function(spec)
    vim.notify(
      string.format("%s → %s/%s\nvalues: %s", spec.label, spec.namespace, spec.release, table.concat(spec.values, ", ")),
      vim.log.levels.INFO,
      { title = "helm" }
    )
  end, { reconfigure = true, refresh = true })
end

return M
