-- terraform templatefile() yaml (values.tpl):
--   * lines holding only a `%{ ... }` directive are not valid yaml and make the tree-sitter
--     error recovery wreck everything below them: keep them out of the yaml parse
--     (tree-sitter included regions)
--   * `${var}` and `%{ ... }` get their own highlight (TfTplVar / TfTplDirective)
--   * `K` / `gd` on a template variable resolve it in the `templatefile(...)` call of the
--     sibling .tf files (and `var.x` further to its variable block)
local M = {}

local DIRECTIVE = "^%s*%%{.*}%s*$"
local ns = vim.api.nvim_create_namespace("tftpl")

vim.api.nvim_set_hl(0, "TfTplVar", { link = "Special", default = true })
vim.api.nvim_set_hl(0, "TfTplDirective", { link = "PreProc", default = true })

-- ── parse / highlight ─────────────────────────────────────────────────────────

---Every `${ ... }` (braces balanced, may span lines) as {srow, scol, erow, ecol}: 0-based,
---end exclusive.
local function interpolations(lines)
  local out = {}
  local row, col = 1, 1
  while row <= #lines do
    local s = lines[row]:find("${", col, true)
    if not s then
      row, col = row + 1, 1
    else
      local depth, r, c, found = 0, row, s + 1, nil
      while r <= #lines and not found do
        local ch = lines[r]:sub(c, c)
        if ch == "" then
          r, c = r + 1, 1
        else
          if ch == "{" then
            depth = depth + 1
          elseif ch == "}" then
            depth = depth - 1
            found = depth == 0
          end
          c = c + 1
        end
      end
      if not found then
        return out
      end
      table.insert(out, { row - 1, s - 1, r - 1, c - 1 })
      row, col = r, c
    end
  end
  return out
end

---Ranges covering everything except directive lines and `${...}` spans: yaml sees
---`tag: ` for `tag: ${split(":", x)[1]}`, which parses fine.
local function ranges(lines, spans)
  local cuts = {}
  for i, line in ipairs(lines) do
    if line:match(DIRECTIVE) then
      table.insert(cuts, { i - 1, 0, i, 0 })
    end
  end
  vim.list_extend(cuts, spans)
  table.sort(cuts, function(a, b)
    return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
  end)

  local out = {}
  local row, col = 0, 0 -- start of the pending included range
  for _, cut in ipairs(cuts) do
    -- spans nested in an already cut directive line
    if cut[3] < row or (cut[3] == row and cut[4] <= col) then
      goto continue
    end
    if cut[1] > row or (cut[1] == row and cut[2] > col) then
      table.insert(out, { row, col, cut[1], cut[2] })
    end
    row, col = cut[3], cut[4]
    ::continue::
  end
  table.insert(out, { row, col, #lines, 0 })
  return out
end

local function refresh(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local spans = interpolations(lines)

  local ok, parser = pcall(vim.treesitter.get_parser, buf, "yaml")
  if ok and parser then
    parser:set_included_regions({ ranges(lines, spans) })
  end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, line in ipairs(lines) do
    if line:match(DIRECTIVE) then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        end_row = i - 1,
        end_col = #line,
        hl_group = "TfTplDirective",
        priority = 300,
      })
    end
  end
  for _, span in ipairs(spans) do
    vim.api.nvim_buf_set_extmark(buf, ns, span[1], span[2], {
      end_row = span[3],
      end_col = span[4],
      hl_group = "TfTplVar",
      priority = 300,
    })
  end
end

-- ── K / gd: template variable -> templatefile() argument in the .tf files ─────

---Template variable under the cursor (inside `${...}` or on a directive line).
local function var_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local function ident_at(text, offset)
    local init = 1
    while true do
      local s, e = text:find("[%a_][%w_]*", init)
      if not s then
        return nil
      end
      if offset + s <= col and col <= offset + e then
        return text:sub(s, e)
      end
      init = e + 1
    end
  end
  local init = 1
  while true do
    local s, e = line:find("%${[^}]*}", init)
    if not s then
      break
    end
    if s <= col and col <= e then
      -- cursor on `${`, `}` or an operator: fall back to the first identifier inside
      return ident_at(line:sub(s + 2, e - 1), s + 1) or line:sub(s + 2, e - 1):match("[%a_][%w_]*")
    end
    init = e + 1
  end
  if line:match(DIRECTIVE) then
    return ident_at(line, 0)
  end
end

local function tf_files(dir)
  return vim.fn.glob(dir .. "/*.tf", false, true)
end

---Find `<name> = <expr>` inside the map passed to templatefile("…/<tpl>", { … }).
local function find_argument(dir, tpl, name)
  for _, file in ipairs(tf_files(dir)) do
    local lines = vim.fn.readfile(file)
    for i, line in ipairs(lines) do
      if line:find("templatefile(", 1, true) and line:find(tpl, 1, true) then
        local depth = 0
        for j = i, #lines do
          local l = lines[j]
          if j > i and depth == 1 then
            local expr = l:match("^%s*" .. vim.pesc(name) .. "%s*=%s*(.-)%s*$")
            if expr then
              return { file = file, lnum = j, expr = expr }
            end
          end
          depth = depth + select(2, l:gsub("{", "")) - select(2, l:gsub("}", ""))
          if j > i and depth <= 0 then
            break
          end
        end
      end
    end
  end
end

---Text of `<kind> "<name>" { ... }` (variable) or the `<name> = ...` line (local).
local function find_definition(dir, kind, name)
  for _, file in ipairs(tf_files(dir)) do
    local lines = vim.fn.readfile(file)
    for i, line in ipairs(lines) do
      if kind == "var" and line:match('^variable%s+"' .. vim.pesc(name) .. '"') then
        local block = {}
        for j = i, #lines do
          table.insert(block, lines[j])
          if lines[j]:match("^}") then
            break
          end
        end
        return { file = file, lnum = i, text = table.concat(block, "\n") }
      elseif kind == "local" and line:match("^%s+" .. vim.pesc(name) .. "%s*=") then
        return { file = file, lnum = i, text = vim.trim(line) }
      end
    end
  end
end

---Substitute `{{ .X }}` in a Taskfile string with the Taskfile context (or its default).
local function render(str, ctx, defaults)
  return (str:gsub("{{%s*%.([%w_]+)[^}]*}}", function(key)
    return ctx[key] or defaults[key] or ""
  end))
end

---`name = value` in a tfvars file; multi-line values are collected until braces balance.
local function tfvars_value(file, name)
  if vim.fn.filereadable(file) ~= 1 then
    return
  end
  local lines = vim.fn.readfile(file)
  for i, line in ipairs(lines) do
    local raw = line:match("^%s*" .. vim.pesc(name) .. "%s*=%s*(.-)%s*$")
    if raw then
      local text = { (raw:gsub("%s+#.*$", "")) }
      local depth = select(2, raw:gsub("[{%[]", "")) - select(2, raw:gsub("[}%]]", ""))
      local j = i
      while depth > 0 and j < #lines do
        j = j + 1
        table.insert(text, lines[j])
        depth = depth + select(2, lines[j]:gsub("[{%[]", "")) - select(2, lines[j]:gsub("[}%]]", ""))
      end
      return { text = table.concat(text, "\n"), file = file, lnum = i }
    end
  end
end

---Value terraform gets for `var.<name>` in the module of this buffer: -var from the Taskfile
---(task context), then -var-file / auto tfvars, then the variable's default.
local function var_value(buf, dir, name, def)
  local ok, root, ctx = pcall(function()
    return require("functions.taskfile").resolve(buf)
  end)
  local ctx_line
  if ok and root then
    local taskfile = vim.fs.find({ "Taskfile.yaml", "Taskfile.yml" }, { path = root, limit = 1, upward = false })[1]
    local text = taskfile and table.concat(vim.fn.readfile(taskfile), "\n") or ""
    local defaults = {}
    for key, val in text:gmatch('([%u_]+):%s*[\'"]{{%s*%.[%u_]+%s*|%s*default%s*"([^"]*)"') do
      defaults[key] = val
    end
    ctx_line = vim.trim(vim.inspect({ DOMAIN = ctx.DOMAIN, TIER = ctx.TIER, REGION = ctx.REGION }):gsub("%s+", " "))

    -- -var="name={{ .X }}"  /  -var=name="{{ .X }}"
    for var, key in text:gmatch('%-var=?"?([%w_]+)="?{{%s*%.([%w_]+)') do
      if var == name and (ctx[key] or defaults[key]) then
        return { text = '"' .. (ctx[key] or defaults[key]) .. '"', source = ("Taskfile -var (%s)"):format(key), ctx = ctx_line }
      end
    end
    -- -var-file="config/{{ .DOMAIN }}-{{ .TIER }}-{{ .REGION }}.tfvars"
    for tpl in text:gmatch('%-var%-file="([^"]+)"') do
      local found = tfvars_value(vim.fs.normalize(dir .. "/" .. render(tpl, ctx, defaults)), name)
      if found then
        found.source = ("%s:%d"):format(vim.fn.fnamemodify(found.file, ":.:s?^.*/terraform/??"), found.lnum)
        found.ctx = ctx_line
        return found
      end
    end
  end
  for _, file in ipairs(vim.list_extend({ dir .. "/terraform.tfvars" }, vim.fn.glob(dir .. "/*.auto.tfvars", false, true))) do
    local found = tfvars_value(file, name)
    if found then
      found.source = ("%s:%d"):format(vim.fs.basename(file), found.lnum)
      found.ctx = ctx_line
      return found
    end
  end
  local default = def and def.text:match("\n%s*default%s*=%s*(.-)\n[%s}]*$")
  if default then
    return { text = default, source = "default", ctx = ctx_line }
  end
  return { source = "no value found (passed at plan time?)", ctx = ctx_line }
end

local function resolve(buf)
  local name = var_at_cursor()
  if not name then
    return
  end
  local path = vim.api.nvim_buf_get_name(buf)
  local dir, tpl = vim.fs.dirname(path), vim.fs.basename(path)
  local arg = find_argument(dir, tpl, name)
  if not arg then
    return
  end
  local kind, ref = arg.expr:match("^(var)%.([%w_]+)%s*$")
  if not kind then
    kind, ref = arg.expr:match("^(local)%.([%w_]+)%s*$")
  end
  local def = ref and find_definition(dir, kind, ref) or nil
  local value
  if kind == "var" and ref then
    value = var_value(buf, dir, ref, def)
  end
  return name, arg, def, value
end

M.resolve = resolve

function M.is_tpl(buf)
  return vim.api.nvim_buf_get_name(buf):match("%.tpl$") ~= nil and vim.bo[buf].filetype == "yaml"
end

function M.hover(buf)
  local name, arg, def, value = resolve(buf)
  if not name then
    return vim.lsp.buf.hover()
  end
  local rel = vim.fn.fnamemodify(arg.file, ":t") .. ":" .. arg.lnum
  local md = { ("**%s** — `%s`"):format(name, rel), "", "```hcl", name .. " = " .. arg.expr, "```" }
  if value then
    vim.list_extend(md, { "", "**value** `" .. value.source .. "`" })
    if value.text then
      vim.list_extend(md, { "```hcl", value.text, "```" })
    end
    if value.ctx then
      table.insert(md, "context: `" .. value.ctx .. "`")
    end
  elseif not arg.expr:match("^[%w_]+%.") then
    table.insert(md, "")
  else
    vim.list_extend(md, { "", "**value** not statically known (`" .. arg.expr:match("^[%w_]+") .. "` reference, resolved by terraform at plan/apply)" })
  end
  if def then
    vim.list_extend(md, { "", ("`%s:%d`"):format(vim.fn.fnamemodify(def.file, ":t"), def.lnum), "```hcl" })
    vim.list_extend(md, vim.split(def.text, "\n"))
    table.insert(md, "```")
  end
  vim.lsp.util.open_floating_preview(md, "markdown", { border = "rounded", focus_id = "tftpl_hover" })
end

function M.definition(buf)
  local _, arg = resolve(buf)
  if not arg then
    return vim.lsp.buf.definition()
  end
  vim.cmd.edit(arg.file)
  vim.api.nvim_win_set_cursor(0, { arg.lnum, 0 })
end

function M.attach(buf)
  if vim.b[buf].tftpl_attached then
    return
  end
  vim.b[buf].tftpl_attached = true
  refresh(buf)

  local timer = assert(vim.uv.new_timer())
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      timer:stop()
      timer:start(30, 0, vim.schedule_wrap(function()
        refresh(buf)
      end))
    end,
    on_detach = function()
      timer:close()
    end,
  })

end

return M
