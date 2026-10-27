local M = {}

--- INTEGRATION: Require shared state and the test runner itself for callbacks.

local integration_state = require("functions.alloy_integration_state")

local tester = require("functions.alloy_e2e_tests")

--- PERFORMANCE: Cache for parsed buffer data.

local cache = {

  bufnr = nil,

  components = nil,

  all_chains_by_key = nil,

  start_nodes = nil,

  -- Use a structural hash instead of changedtick for smarter caching

  structural_hash = nil,
}

local ns_id = vim.api.nvim_create_namespace("AlloyPipelineVtext")

local ns_id_follow = vim.api.nvim_create_namespace("AlloyPipelineFollow")

local ns_id_dim = vim.api.nvim_create_namespace("AlloyPipelineDim")

local ns_id_results = vim.api.nvim_create_namespace("AlloyPipelineResults")

--- FEATURE: Namespace for override icons in the source buffer.

local ns_id_override_icon = vim.api.nvim_create_namespace("AlloyOverrideIcon")

-- ===================================================================

-- 🎨 Style and Icon Definitions

-- ===================================================================

local tokyonight_futuristic_hls = {

  key_order = { "Sky", "Green", "Coral", "Lavender", "Teal", "Storm" },

  Storm = { fg = "#7aa2f7" },

  Teal = { fg = "#73daca" },

  Green = { fg = "#9ece6a" },

  Lavender = { fg = "#bb9af7" },

  Sky = { fg = "#89ddff" },

  Coral = { fg = "#ff9e64" },

  Follow = { bg = "#3b4261" },

  Dimmed = { fg = "#565f89" },

  Filter = { link = "@punctuation.special" },

  FilterInactive = { link = "Comment" },

  StageHeader = { fg = "#e0af68", bold = true },

  ComponentBaseText = { fg = "#a9b1d6" },

  ComponentTypeBold = { link = "@type.builtin" },

  ComponentLabelDim = { link = "Comment" },

  BranchIcon = { fg = "#f7768e" },

  TreeConnector = { fg = "#3b4261" },

  Arrow = { link = "TreeConnector" },

  BorderChars = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
}

local futuristic_process_icons = {

  source = "",

  process = "",

  write = "󰒍",

  relabel = "",

  scrape = "󰥟",

  remote_write = "󰛶",

  file_match = "󰈞",

  file = "󰈞",

  default = "",
}

local pipeline_hls = tokyonight_futuristic_hls

local process_icons = futuristic_process_icons

M._highlights_set = false

M.diagram_state = nil

M._is_syncing = false

local function _setup_highlights()
  if M._highlights_set then
    return
  end

  for name, hl_definition in pairs(pipeline_hls) do
    if name ~= "key_order" and name ~= "Arrow" and name ~= "BorderChars" then
      local diagram_hl_name = "DiagramBox" .. name

      vim.api.nvim_set_hl(0, diagram_hl_name, hl_definition)
    end
  end

  vim.api.nvim_set_hl(0, "DiagramDimmedText", pipeline_hls.Dimmed)

  vim.api.nvim_set_hl(0, "DiagramArrow", pipeline_hls.Arrow)

  vim.api.nvim_set_hl(0, "DiagramBorder", { fg = pipeline_hls.Storm.fg })

  vim.api.nvim_set_hl(0, "DiagramBoxSuccess", { fg = "#9ece6a" })

  vim.api.nvim_set_hl(0, "DiagramBoxFailure", { fg = "#f7768e" })

  vim.api.nvim_set_hl(0, "AlloyDiffAdd", { bg = "#24332A" })

  vim.api.nvim_set_hl(0, "AlloyDiffDelete", { bg = "#392A30" })

  --- BUGFIX: Set background to NONE to prevent clash with CursorLine.

  vim.api.nvim_set_hl(0, "AlloyOverrideIcon", { fg = "#e0af68", bg = "NONE", default = true })

  M._highlights_set = true
end

-- ===================================================================

-- Parser and Utility Functions

-- ===================================================================

--- PERFORMANCE FIX: Caching logic is now based on a structural hash.

local function _get_parsed_pipeline_data(bufnr)
  -- Step 1: Quickly get just the component names to create a "structural hash".

  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local component_keys = {}

  for _, line in ipairs(buffer_lines) do
    for type, label in line:gmatch('^%s*([%w_%.]+)%s+"([%w_%.]+)"%s*{') do
      table.insert(component_keys, type .. "." .. label)
    end
  end

  table.sort(component_keys)

  local structural_hash = table.concat(component_keys, ";")

  -- Step 2: Compare with the cached hash.

  if cache.bufnr == bufnr and cache.structural_hash == structural_hash and cache.components then
    integration_state.notify_debug("Cache hit: structure unchanged.")

    return cache.components, cache.all_chains_by_key, cache.start_nodes
  end

  integration_state.notify_debug("Cache miss: structure changed. Re-parsing pipeline.")

  -- Step 3: If hashes differ, perform the full, expensive parse.

  local buffer_content = table.concat(buffer_lines, "\n")

  local clean_content = buffer_content:gsub("/%*.-%*/", function(comment)
    return comment:gsub("[^\n]", " ")
  end)

  clean_content = clean_content:gsub("//[^\n]*", function(comment)
    return comment:gsub(".", " ")
  end)

  local components, forward_targets = {}, {}

  do
    local search_offset = 1

    local pattern = '([%w_%.]+)%s+"([%w_%.]+)"%s*{'

    while true do
      local s, e, c_type, c_label = clean_content:find(pattern, search_offset)

      if not s then
        break
      end

      local line_num = 1 + select(2, clean_content:sub(1, s):gsub("\n", ""))

      local brace_level, content_end = 1, -1

      for i = e + 1, #clean_content do
        local char = clean_content:sub(i, i)

        if char == "{" then
          brace_level = brace_level + 1
        elseif char == "}" then
          brace_level = brace_level - 1

          if brace_level == 0 then
            content_end = i

            break
          end
        end
      end

      if content_end ~= -1 then
        local c_content = clean_content:sub(e + 1, content_end - 1)

        local end_line = 1 + select(2, clean_content:sub(1, content_end):gsub("\n", ""))

        local original_block_content =
          
table.concat(vim.api.nvim_buf_get_lines(bufnr, line_num - 1, end_line, false), "\n")

        components[c_type .. "." .. c_label] = {

          type = c_type,

          label = c_label,

          content = c_content,

          line = line_num,

          end_line = end_line,

          original_block_content = original_block_content,
        }

        search_offset = content_end + 1
      else
        search_offset = e + 1
      end
    end
  end

  if vim.tbl_isempty(components) then
    return nil, nil, nil
  end

  local receives_from = {}

  for key, comp in pairs(components) do
    local forward_content = comp.content:match("forward_to%s*=%s*%[([^]]+)%]")

    if forward_content then
      if not comp.forward_to then
        comp.forward_to = {}
      end

      forward_content = forward_content:gsub("//[^\n]*", ""):gsub("\n", " ")

      for target in forward_content:gmatch("([%w_%.]+%.receiver)") do
        local target_key = target:match("([%w_%.]+)%.receiver")

        if target_key then
          table.insert(comp.forward_to, target_key)

          forward_targets[target_key] = true

          if not receives_from[target_key] then
            receives_from[target_key] = {}
          end

          table.insert(receives_from[target_key], key)
        end
      end
    end

    for provider_key in comp.content:gmatch("targets%s*=%s*([%w_%.]+)%.targets") do
      if components[provider_key] then
        if not components[provider_key].forward_to then
          components[provider_key].forward_to = {}
        end

        table.insert(components[provider_key].forward_to, key)

        forward_targets[key] = true

        if not receives_from[key] then
          receives_from[key] = {}
        end

        table.insert(receives_from[key], provider_key)
      end
    end
  end

  for key, sources in pairs(receives_from) do
    if components[key] then
      components[key].receives_from = sources
    end
  end

  local start_nodes = {}

  for key, _ in pairs(components) do
    if not forward_targets[key] and not key:match("write") and not key:match("export") then
      table.insert(start_nodes, key)
    end
  end

  if #start_nodes == 0 then
    return nil, nil, nil
  end

  local all_chains_by_key = {}

  for _, start_key in ipairs(start_nodes) do
    local stack = { { start_key } }

    while #stack > 0 do
      local current_path_keys = table.remove(stack)

      local last_key_in_path = current_path_keys[#current_path_keys]

      local node = components[last_key_in_path]

      if node and node.forward_to and #node.forward_to > 0 then
        for _, next_key in ipairs(node.forward_to) do
          if not vim.tbl_contains(current_path_keys, next_key) then
            local new_path = vim.deepcopy(current_path_keys)

            table.insert(new_path, next_key)

            table.insert(stack, new_path)
          end
        end
      else
        table.insert(all_chains_by_key, current_path_keys)
      end
    end
  end

  local color_index = 1

  for _, chain_keys in ipairs(all_chains_by_key) do
    local color_name = pipeline_hls.key_order[color_index]

    for _, key in ipairs(chain_keys) do
      if components[key] and not components[key].color then
        components[key].color = color_name
      end
    end

    color_index = (color_index % #pipeline_hls.key_order) + 1
  end

  --- PERFORMANCE: Update the cache with the new data.

  cache.bufnr = bufnr

  cache.components = components

  cache.all_chains_by_key = all_chains_by_key

  cache.start_nodes = start_nodes

  cache.structural_hash = structural_hash

  return components, all_chains_by_key, start_nodes
end

function M.get_box_at_cursor(win_id, metadata, diagram_type)
  if not win_id or not vim.api.nvim_win_is_valid(win_id) then
    return nil, nil
  end

  local pos = vim.api.nvim_win_get_cursor(win_id)

  local r, c = pos[1], pos[2]

  for i, box in ipairs(metadata) do
    if diagram_type == "horizontal" then
      if r >= box.line_in_diagram and r <= box.line_in_diagram + 3 and c >= box.start_col and c <= box.end_col then
        return i, box
      end
    elseif diagram_type == "vertical_list" then
      if r == box.line_in_diagram then
        return i, box
      end
    end
  end

  return nil, nil
end

function M.create_top_split_window(buf, height)
  vim.cmd("topleft " .. height .. "split")

  local win_id = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_buf(win_id, buf)

  return win_id
end

function M.create_styled_popup(buf, title, width, height, opts)
  opts = opts or {}

  local win_opts = {

    style = "minimal",

    border = pipeline_hls.BorderChars or "rounded",

    title = " " .. title .. " ",

    title_pos = "center",

    width = width,

    height = height,

    zindex = 50,
  }

  for k, v in pairs(opts) do
    win_opts[k] = v
  end

  if win_opts.relative == "win" and win_opts.win then
    local parent_width = vim.api.nvim_win_get_width(win_opts.win)

    win_opts.row = win_opts.row or 0

    win_opts.col = win_opts.col or math.floor((parent_width - width - 2) / 2)
  else
    win_opts.relative = "editor"

    win_opts.row = win_opts.row or 1

    win_opts.col = win_opts.col or math.floor((vim.o.columns - width - 2) / 2)
  end

  local win_id = vim.api.nvim_open_win(buf, true, win_opts)

  vim.wo[win_id].winhighlight = "Normal:Normal,FloatBorder:DiagramBorder,FloatTitle:DiagramBoxStageHeader"

  return win_id
end

function M.create_selection_popup(items, opts, on_confirm)
  local parent_win_id = opts.parent_win_id

  if not (parent_win_id and vim.api.nvim_win_is_valid(parent_win_id)) then
    return
  end

  local parent_config = vim.api.nvim_win_get_config(parent_win_id)

  local lines = {}

  for _, item in ipairs(items) do
    table.insert(lines, "" .. item.display)
  end

  local height = #lines

  local width = 0

  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strwidth(line))
  end

  width = width + 4

  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"

  vim.bo[buf].swapfile = false

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local popup_win_id = vim.api.nvim_open_win(buf, true, {

    relative = "win",

    win = parent_win_id,

    style = "minimal",

    border = "rounded",

    title = opts.prompt or "Select One",

    title_pos = "center",

    width = width,

    height = height,

    row = -height - 2,

    col = math.floor((parent_config.width - width) / 2),

    zindex = 200,
  })

  vim.wo[popup_win_id].cursorline = true

  vim.wo[popup_win_id].number = false

  vim.wo[popup_win_id].relativenumber = false

  local function cleanup_and_close()
    if vim.api.nvim_win_is_valid(popup_win_id) then
      vim.api.nvim_win_close(popup_win_id, true)
    end

    if vim.api.nvim_win_is_valid(parent_win_id) then
      vim.api.nvim_set_current_win(parent_win_id)
    end
  end

  vim.keymap.set("n", "<CR>", function()
    local cursor_pos = vim.api.nvim_win_get_cursor(popup_win_id)

    local selected_line_num = cursor_pos[1]

    local selected_item = items[selected_line_num]

    cleanup_and_close()

    if selected_item then
      on_confirm(selected_item)
    end
  end, { buffer = buf, silent = true, nowait = true, desc = "Confirm selection" })

  vim.keymap.set("n", "q", cleanup_and_close, { buffer = buf, silent = true, nowait = true, desc = "Close selection" })

  vim.keymap.set(
    "n",
    "<Esc>",
    cleanup_and_close,
    { buffer = buf, silent = true, nowait = true, desc = "Close selection" }
  )
end

function M.close_component_popup()
  if M.diagram_state and M.diagram_state.popup_win_id and vim.api.nvim_win_is_valid(M.diagram_state.popup_win_id) then
    vim.api.nvim_win_close(M.diagram_state.popup_win_id, true)

    M.diagram_state.popup_win_id = nil
  end
end

function M.close_help_popup()
  if

    M.diagram_state
    and M.diagram_state.help_popup_win_id
    and vim.api.nvim_win_is_valid(M.diagram_state.help_popup_win_id)
  then
    vim.api.nvim_win_close(M.diagram_state.help_popup_win_id, true)

    M.diagram_state.help_popup_win_id = nil
  end
end

--- UX: Use the standardized styled popup for help.

function M.create_help_popup(diagram_type)
  M.close_help_popup()

  local keymaps

  if diagram_type == "vertical_list" then
    keymaps = {

      { "<Tab>/<S-Tab>", "Navigate components" },

      { "o", "Add new component below cursor" },

      { "<CR>", "Jump to component in source" },

      { "<leader>k", "Show component code preview" },

      { "f", "Set new filter" },

      { "c", "Clear filter" },

      { "<leader>t", "Run E2E test for the whole file" },

      { "<leader>te", "Edit this component's override file" },

      { "q", "Close diagram / popup" },

      { "g?", "Show this help menu" },
    }
  else -- "horizontal"
    keymaps = {

      { "<Tab>/<S-Tab>", "Navigate components" },

      { "p", "Focus/unfocus pipeline" },

      { "<CR>", "Go to Definition (or show Test Summary if failed)" },

      { "<leader>k", "Show component code (or Diff if tested)" },

      { "<leader>t", "Run E2E test for the whole file" },

      { "<leader>te", "Edit this component's override file" },

      { "q", "Close diagram / popup" },

      { "g?", "Show this help menu" },
    }
  end

  local max_key_len = 0

  for _, map in ipairs(keymaps) do
    max_key_len = math.max(max_key_len, vim.fn.strwidth(map[1]))
  end

  local help_content = {}

  for _, map in ipairs(keymaps) do
    local key, desc = map[1], map[2]

    local padding = string.rep(" ", max_key_len - vim.fn.strwidth(key))

    table.insert(help_content, string.format(" %s%s │ %s", key, padding, desc))
  end

  local width = 0

  for _, line in ipairs(help_content) do
    width = math.max(width, vim.fn.strwidth(line))
  end

  width = width + 4

  local popup_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, help_content)

  vim.bo[popup_buf].modifiable = false

  local help_win_id = M.create_styled_popup(popup_buf, "Commands", width, #help_content, {

    relative = "win",

    win = M.diagram_state.win_id,

    row = 2,

    col = 5,

    zindex = 150,
  })

  vim.keymap.set("n", "q", function()
    M.close_help_popup()
  end, { buffer = popup_buf, silent = true, desc = "Close help" })

  vim.keymap.set("n", "g?", function()
    M.close_help_popup()
  end, { buffer = popup_buf, silent = true, desc = "Close help" })

  M.diagram_state.help_popup_win_id = help_win_id
end

--- BUGFIX: Re-implemented diffing to use external `diff` command via temp files.

function M.open_component_popup(box, opts)
  opts = opts or {}

  if not (box and (box.content or box.is_overridden)) then
    return
  end

  local content_lines, popup_title, filetype

  local highlights = {}

  local is_diff_view = box.is_overridden

  if is_diff_view then
    popup_title = "Component Diff: " .. box.original_type .. "." .. box.original_label

    filetype = "diff"

    local original_code = box.original_block_content

    local override_code = tester.get_override_content(box.original_type .. "-" .. box.original_label)

    if not override_code then
      content_lines = { "Error: Could not load override file." }
    else
      local original_file = vim.fn.tempname()

      local override_file = vim.fn.tempname()

      vim.fn.writefile(vim.split(original_code, "\n"), original_file)

      vim.fn.writefile(vim.split(override_code, "\n"), override_file)

      -- Use -u for a unified diff format

      local diff_result = vim.fn.system({ "diff", "-u", original_file, override_file })

      vim.fn.delete(original_file)

      vim.fn.delete(override_file)

      content_lines = vim.split(diff_result, "\n")

      for i, line in ipairs(content_lines) do
        if line:sub(1, 1) == "+" and not line:match("^%+%+%+") then
          table.insert(highlights, { line = i, hl = "AlloyDiffAdd" })
        elseif line:sub(1, 1) == "-" and not line:match("^%-%-%-") then
          table.insert(highlights, { line = i, hl = "AlloyDiffDelete" })
        end
      end
    end
  else
    popup_title = "Component Code: " .. box.original_type .. "." .. box.original_label

    filetype = "river"

    content_lines = vim.split(box.content, "\n")
  end

  local popup_buf = vim.api.nvim_create_buf(false, true)

  vim.bo[popup_buf].filetype = filetype

  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, content_lines)

  local win_opts = { style = "minimal", border = "rounded", title = popup_title, title_pos = "center", zindex = 100 }

  if opts.layout == "horizontal_manual" then
    local diagram_win_config = vim.api.nvim_win_get_config(opts.parent_win_id)

    local popup_top_row = diagram_win_config.row + box.line_in_diagram + 3

    win_opts.relative = "editor"

    win_opts.width = vim.o.columns

    win_opts.height = math.max(1, vim.o.lines - popup_top_row - 1)

    win_opts.row = popup_top_row

    win_opts.col = 0

    win_opts.focusable = true
  else
    local width = 0

    for _, line in ipairs(content_lines) do
      width = math.max(width, vim.fn.strwidth(line))
    end

    win_opts.width = math.min(width + 4, 120)

    win_opts.height = math.min(#content_lines, 25)

    win_opts.relative = "cursor"

    win_opts.row = 1

    win_opts.col = 3

    win_opts.focusable = false
  end

  local popup_win_id = vim.api.nvim_open_win(popup_buf, true, win_opts)

  for _, hl_data in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(popup_buf, -1, hl_data.hl, hl_data.line - 1, 0, -1)
  end

  vim.keymap.set("n", "q", function()
    M.close_component_popup()

    if M.diagram_state and M.diagram_state.win_id and vim.api.nvim_win_is_valid(M.diagram_state.win_id) then
      vim.api.nvim_set_current_win(M.diagram_state.win_id)
    end
  end, { buffer = popup_buf, silent = true, desc = "Close popup" })

  return popup_win_id
end

function M.GetPipelineSteps(source_bufnr)
  local components, all_chains_by_key, _ = _get_parsed_pipeline_data(source_bufnr)

  if not components or not all_chains_by_key then
    return nil
  end

  local all_chains_with_data = {}

  for _, chain_keys in ipairs(all_chains_by_key) do
    local final_chain = {}

    for _, key in ipairs(chain_keys) do
      local node = components[key]

      if node then
        table.insert(final_chain, {

          key = key,

          label = " " .. node.type .. " (" .. node.label .. ")",

          source_line = node.line,

          color = node.color or "Comment",

          original_type = node.type,

          original_label = node.label,

          content = node.content,

          original_block_content = node.original_block_content,
        })
      end
    end

    table.insert(all_chains_with_data, final_chain)
  end

  local chains_by_start = {}

  for _, chain in ipairs(all_chains_with_data) do
    if #chain > 0 then
      local start_label = chain[1].label

      if not chains_by_start[start_label] then
        chains_by_start[start_label] = {}
      end

      table.insert(chains_by_start[start_label], chain)
    end
  end

  return chains_by_start
end

-- ===================================================================

-- Core Commands

-- ===================================================================

function M.edit_override_file()
  local component_type, component_label

  if

    M.diagram_state
    and vim.api.nvim_win_is_valid(M.diagram_state.win_id)
    and vim.api.nvim_get_current_win() == M.diagram_state.win_id
  then
    local _, box = M.get_box_at_cursor(M.diagram_state.win_id, M.diagram_state.box_metadata, M.diagram_state.type)

    if box then
      component_type = box.original_type

      component_label = box.original_label
    else
      print("Cursor is not on a component box.")

      return
    end
  else
    local current_buf = vim.api.nvim_get_current_buf()

    local components, _, _ = _get_parsed_pipeline_data(current_buf)

    if not components then
      print("Could not parse Alloy components in this buffer.")

      return
    end

    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

    local found = false

    for _, comp_data in pairs(components) do
      if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
        component_type = comp_data.type

        component_label = comp_data.label

        found = true

        break
      end
    end

    if not found then
      print("Cursor is not inside a recognized component block.")

      return
    end
  end

  if not (component_type and component_label) then
    print("Could not identify component.")

    return
  end

  local override_key = component_type .. "-" .. component_label

  local override_dir = vim.fn.getcwd() .. "/.alloy_tests/" .. override_key

  local override_file = override_dir .. "/localtest.alloy"

  if vim.fn.filereadable(override_file) == 1 then
    vim.cmd("vsplit " .. vim.fn.fnameescape(override_file))
  else
    print("No override file found for " .. override_key)

    vim.ui.input({ prompt = "Override file not found. Create it? (y/n)", default = "y" }, function(input)
      if input and input:lower() == "y" then
        vim.fn.mkdir(override_dir, "p")

        vim.fn.writefile({ component_type .. ' "' .. component_label .. '" {' .. "}" }, override_file)

        vim.cmd("vsplit " .. vim.fn.fnameescape(override_file))
      end
    end)
  end
end

function M.show_override_icons_in_buffer()
  local bufnr = vim.api.nvim_get_current_buf()

  tester.update_override_state()

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id_override_icon, 0, -1)

  local components, _, _ = _get_parsed_pipeline_data(bufnr)

  if not components then
    return
  end

  for _, comp_data in pairs(components) do
    local override_key = comp_data.type .. "-" .. comp_data.label

    if integration_state.overridden_components[override_key] then
      vim.api.nvim_buf_set_extmark(
        bufnr,
        ns_id_override_icon,
        comp_data.line - 1,
        -1,
        { virt_text = { { " 🧪", "AlloyOverrideIcon" } }, virt_text_pos = "eol" }
      )
    end
  end
end

function M.clear_override_icons_in_buffer()
  local bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id_override_icon, 0, -1)

  print("Cleared test override icons.")
end

function M.show_diff_popup_from_buffer()
  local bufnr = vim.api.nvim_get_current_buf()

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  tester.update_override_state()

  local components, _, _ = _get_parsed_pipeline_data(bufnr)

  if not components then
    return
  end

  local found_component = nil

  for _, comp_data in pairs(components) do
    if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
      found_component = comp_data

      break
    end
  end

  if not found_component then
    return
  end

  local override_key = found_component.type .. "-" .. found_component.label

  if integration_state.overridden_components[override_key] then
    integration_state.notify_debug("Showing diff for " .. override_key)

    local box_data = {

      original_type = found_component.type,

      original_label = found_component.label,

      is_overridden = true,

      original_block_content = found_component.original_block_content,
    }

    M.open_component_popup(box_data, {})
  else
    integration_state.notify_debug("No override found for " .. override_key .. ". Key does nothing.")
  end
end

function M.ShowPipelineNumbers()
  _setup_highlights()

  local current_buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_clear_namespace(current_buf, ns_id, 0, -1)

  local components, all_chains_by_key, _ = _get_parsed_pipeline_data(current_buf)

  if not components or not all_chains_by_key then
    print("Could not analyze pipelines to show numbers.")

    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local current_component_key = nil

  for key, comp_data in pairs(components) do
    if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
      current_component_key = key

      break
    end
  end

  if not current_component_key then
    print("Cursor is not inside a recognized component block.")

    return
  end

  local chains_to_number = vim.tbl_filter(function(chain)
    return vim.tbl_contains(chain, current_component_key)
  end, all_chains_by_key)

  if #chains_to_number > 0 then
    local numbered_count, already_numbered = 0, {}

    for _, chain in ipairs(chains_to_number) do
      for i, key in ipairs(chain) do
        if not already_numbered[key] then
          local comp_data = components[key]

          if comp_data and comp_data.line then
            local icon_text = "  "
              .. i
              .. ((comp_data.forward_to and #comp_data.forward_to > 1) and ("  " .. #comp_data.forward_to) or "")

            vim.api.nvim_buf_set_extmark(
              current_buf,
              ns_id,
              comp_data.line - 1,
              0,
              { virt_text = { { icon_text .. " ", "Comment" } }, virt_text_pos = "eol" }
            )

            already_numbered[key], numbered_count = true, numbered_count + 1
          end
        end
      end
    end

    print(string.format("Numbered %d component(s) across %d pipeline(s).", numbered_count, #chains_to_number))
  else
    print("Could not determine a pipeline for the current component.")
  end
end

function M.JumpToNextComponent()
  local current_buf = vim.api.nvim_get_current_buf()

  local components, _, _ = _get_parsed_pipeline_data(current_buf)

  if not components then
    print("Could not analyze pipeline.")

    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local current_component_key

  for key, comp_data in pairs(components) do
    if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
      current_component_key = key

      break
    end
  end

  if not current_component_key then
    print("Cursor is not inside a recognized component block.")

    return
  end

  local targets = components[current_component_key].forward_to

  if not targets or #targets == 0 then
    print("End of pipeline branch.")

    return
  end

  local function do_jump(target_key)
    local target_data = components[target_key]

    if not target_data then
      print("Error: Target component '" .. target_key .. "' not found.")

      return
    end

    vim.api.nvim_win_set_cursor(0, { target_data.line, 0 })

    vim.cmd("normal! zt")
  end

  if #targets == 1 then
    do_jump(targets[1])
  else
    vim.ui.select(targets, { prompt = "Jump to which component?" }, function(choice)
      if choice then
        do_jump(choice)
      end
    end)
  end
end

function M.JumpToPreviousComponent()
  local current_buf = vim.api.nvim_get_current_buf()

  local components, _, _ = _get_parsed_pipeline_data(current_buf)

  if not components then
    print("Could not analyze pipeline.")

    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local current_component_key

  for key, comp_data in pairs(components) do
    if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
      current_component_key = key

      break
    end
  end

  if not current_component_key then
    print("Cursor is not inside a recognized component block.")

    return
  end

  local parents = components[current_component_key].receives_from

  if not parents or #parents == 0 then
    print("Start of pipeline branch.")

    return
  end

  local function do_jump(target_key)
    local target_data = components[target_key]

    if not target_data then
      print("Error: Target component '" .. target_key .. "' not found.")

      return
    end

    vim.api.nvim_win_set_cursor(0, { target_data.line, 0 })

    vim.cmd("normal! zt")
  end

  if #parents == 1 then
    do_jump(parents[1])
  else
    vim.ui.select(parents, { prompt = "Jump to which component?" }, function(choice)
      if choice then
        do_jump(choice)
      end
    end)
  end
end

function M.JumpToNextBlockInFile()
  local current_buf = vim.api.nvim_get_current_buf()

  local components, _, _ = _get_parsed_pipeline_data(current_buf)

  if not components or vim.tbl_isempty(components) then
    return
  end

  local sorted_components = {}

  for _, comp in pairs(components) do
    table.insert(sorted_components, comp)
  end

  table.sort(sorted_components, function(a, b)
    return a.line < b.line
  end)

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local current_idx = 0

  for i, comp in ipairs(sorted_components) do
    if cursor_line >= comp.line and cursor_line <= comp.end_line then
      current_idx = i

      break
    end
  end

  local next_idx = (current_idx % #sorted_components) + 1

  local next_comp = sorted_components[next_idx]

  if next_comp then
    vim.api.nvim_win_set_cursor(0, { next_comp.line, 0 })

    vim.cmd("normal! zz")
  end
end

function M.JumpToPreviousBlockInFile()
  local current_buf = vim.api.nvim_get_current_buf()

  local components, _, _ = _get_parsed_pipeline_data(current_buf)

  if not components or vim.tbl_isempty(components) then
    return
  end

  local sorted_components = {}

  for _, comp in pairs(components) do
    table.insert(sorted_components, comp)
  end

  table.sort(sorted_components, function(a, b)
    return a.line < b.line
  end)

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local current_idx = 0

  for i, comp in ipairs(sorted_components) do
    if cursor_line >= comp.line and cursor_line <= comp.end_line then
      current_idx = i

      break
    end
  end

  local prev_idx

  if current_idx == 0 then
    prev_idx = #sorted_components
  else
    prev_idx = ((current_idx - 2 + #sorted_components) % #sorted_components) + 1
  end

  local prev_comp = sorted_components[prev_idx]

  if prev_comp then
    vim.api.nvim_win_set_cursor(0, { prev_comp.line, 0 })

    vim.cmd("normal! zz")
  end
end

-- ===================================================================

-- Keymap and Navigation Logic

-- ===================================================================

local function _scroll_source_buffer(direction)
  if not M.diagram_state or not M.diagram_state.source_bufnr then
    return
  end

  local source_win_id = vim.fn.bufwinid(M.diagram_state.source_bufnr)

  if source_win_id == -1 then
    return
  end

  local command = (direction == "up") and "normal! \x15" or "normal! \x04"

  vim.fn.win_execute(source_win_id, command)
end

local function _setup_diagram_keymaps()
  local state = M.diagram_state

  if not state then
    return
  end

  local buf = state.buf

  local pipeline_start_boxes = {}

  if #state.pipelines > 0 then
    local start_keys = {}

    for _, p in ipairs(state.pipelines) do
      if #p > 0 then
        start_keys[p[1]] = true
      end
    end

    for _, box in ipairs(state.box_metadata) do
      if start_keys[box.key] then
        table.insert(pipeline_start_boxes, box)
      end
    end

    table.sort(pipeline_start_boxes, function(a, b)
      return a.line_in_diagram < b.line_in_diagram
    end)
  end

  local function get_current_pipeline_index()
    local _, box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)

    if not box then
      return nil
    end

    for i, pipeline in ipairs(state.pipelines) do
      if vim.tbl_contains(pipeline, box.key) then
        return i
      end
    end

    return nil
  end

  local function jump_to_component(key)
    for _, box in ipairs(state.box_metadata) do
      if box.key == key then
        local win_id = state.win_id

        if not (win_id and vim.api.nvim_win_is_valid(win_id)) then
          return
        end

        if state.type == "horizontal" then
          local view = vim.fn.winsaveview()

          local win_width = vim.api.nvim_win_get_width(win_id)

          if state.total_content_width > win_width then
            local max_leftcol = state.total_content_width - win_width

            local box_center_col = box.start_col + math.floor((box.end_col - box.start_col) / 2)

            local desired_leftcol = box_center_col - math.floor(win_width / 2)

            view.leftcol = math.max(0, math.min(desired_leftcol, max_leftcol))
          else
            view.leftcol = 0
          end

          vim.fn.winrestview(view)
        end

        local line = (state.type == "horizontal") and (box.line_in_diagram + 1) or box.line_in_diagram

        local col = (state.type == "horizontal") and (box.start_col + 2) or 2

        vim.api.nvim_win_set_cursor(win_id, { line, col })

        vim.fn.win_execute(win_id, "normal! zz")

        return
      end
    end
  end

  vim.keymap.set("n", "p", function()
    if state.type ~= "horizontal" then
      return
    end

    local current_pipeline_idx = get_current_pipeline_index()

    if not current_pipeline_idx then
      print("Cursor not on a valid pipeline component.")

      return
    end

    local start_node_key = state.pipelines[current_pipeline_idx][1]

    local first_box = nil

    if start_node_key then
      for _, box in ipairs(state.box_metadata) do
        if box.key == start_node_key then
          first_box = box

          break
        end
      end
    end

    if not first_box then
      return
    end

    if state.nav_mode == "component" then
      if state.container_win_id and vim.api.nvim_win_is_valid(state.container_win_id) then
        vim.api.nvim_win_set_height(state.container_win_id, state.original_container_height)

        vim.api.nvim_win_set_config(state.win_id, { height = state.original_container_height - 2 })
      end

      state.nav_mode = "pipeline"

      state.focused_pipeline_index = nil

      print("Navigation: Jumping between pipelines")
    else
      local keys_in_group = {}

      for _, chain in ipairs(state.pipelines) do
        if #chain > 0 and chain[1] == start_node_key then
          for _, key in ipairs(chain) do
            keys_in_group[key] = true
          end
        end
      end

      local min_line, max_line = 9999, 0

      for _, box in ipairs(state.box_metadata) do
        if keys_in_group[box.key] then
          min_line = math.min(min_line, box.line_in_diagram)

          max_line = math.max(max_line, box.line_in_diagram)
        end
      end

      if min_line > max_line then
        return
      end

      local content_height = (max_line - min_line) + 4

      local new_container_height = content_height + 2

      if state.container_win_id and vim.api.nvim_win_is_valid(state.container_win_id) then
        vim.api.nvim_win_set_height(state.container_win_id, new_container_height)

        vim.api.nvim_win_set_config(state.win_id, { height = content_height })
      end

      state.nav_mode = "component"

      state.focused_pipeline_index = current_pipeline_idx

      print("Pipeline focused. Navigation: Jumping between components.")
    end

    local new_cursor_line = first_box.line_in_diagram + 1

    local new_cursor_col = first_box.start_col + 2

    vim.api.nvim_win_set_cursor(state.win_id, { new_cursor_line, new_cursor_col })

    vim.fn.win_execute(state.win_id, "normal! zz")
  end, { buffer = buf, silent = false, desc = "Toggle focus and jump to start" })

  vim.keymap.set("n", "<Tab>", function()
    if state.nav_mode == "component" then
      local _, current_box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)

      if not (current_box and state.focused_pipeline_index) then
        return
      end

      local current_pipeline = state.pipelines[state.focused_pipeline_index]

      local pos_in_pipeline = nil

      for i, key in ipairs(current_pipeline) do
        if key == current_box.key then
          pos_in_pipeline = i

          break
        end
      end

      if pos_in_pipeline and pos_in_pipeline < #current_pipeline then
        jump_to_component(current_pipeline[pos_in_pipeline + 1])
      else
        print("End of focused pipeline.")
      end
    else
      if #pipeline_start_boxes == 0 then
        return
      end

      local pos = vim.api.nvim_win_get_cursor(state.win_id)

      local current_line = pos[1]

      local current_block_index = nil

      for i = #pipeline_start_boxes, 1, -1 do
        if pipeline_start_boxes[i].line_in_diagram <= current_line then
          current_block_index = i

          break
        end
      end

      if current_block_index and current_block_index < #pipeline_start_boxes then
        jump_to_component(pipeline_start_boxes[current_block_index + 1].key)
      else
        print("At last pipeline.")
      end
    end
  end, { buffer = buf, silent = true, desc = "Navigate next" })

  vim.keymap.set("n", "<S-Tab>", function()
    if state.nav_mode == "component" then
      local _, current_box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)

      if not (current_box and state.focused_pipeline_index) then
        return
      end

      local current_pipeline = state.pipelines[state.focused_pipeline_index]

      local pos_in_pipeline = nil

      for i, key in ipairs(current_pipeline) do
        if key == current_box.key then
          pos_in_pipeline = i

          break
        end
      end

      if pos_in_pipeline and pos_in_pipeline > 1 then
        jump_to_component(current_pipeline[pos_in_pipeline - 1])
      else
        print("Start of focused pipeline.")
      end
    else
      if #pipeline_start_boxes == 0 then
        return
      end

      local pos = vim.api.nvim_win_get_cursor(state.win_id)

      local current_line = pos[1]

      local current_block_index = nil

      for i = #pipeline_start_boxes, 1, -1 do
        if pipeline_start_boxes[i].line_in_diagram <= current_line then
          current_block_index = i

          break
        end
      end

      if current_block_index and current_block_index > 1 then
        jump_to_component(pipeline_start_boxes[current_block_index - 1].key)
      else
        print("At first pipeline.")
      end
    end
  end, { buffer = buf, silent = true, desc = "Navigate previous" })

  vim.keymap.set("n", "<C-u>", function()
    _scroll_source_buffer("up")
  end, { buffer = buf, silent = true, desc = "Scroll source up" })

  vim.keymap.set("n", "<C-d>", function()
    _scroll_source_buffer("down")
  end, { buffer = buf, silent = true, desc = "Scroll source down" })

  vim.keymap.set("n", "<CR>", function()
    local _, box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)

    if not box then
      return
    end

    if integration_state.last_summary_data and not integration_state.last_summary_data.test_passed then
      tester.toggle_summary()

      return
    end

    local source_win_id = vim.fn.bufwinid(state.source_bufnr)

    vim.api.nvim_win_close(state.win_id, true)

    if source_win_id ~= -1 then
      vim.api.nvim_set_current_win(source_win_id)
    end

    vim.api.nvim_win_set_cursor(0, { box.source_line, 0 })
  end, { buffer = buf, silent = true, desc = "Go to Definition / Show Test Summary" })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(state.win_id, true)
  end, { buffer = buf, silent = true, desc = "Close diagram" })

  vim.keymap.set("n", "g?", function()
    M.create_help_popup(state.type)
  end, { buffer = buf, silent = true, desc = "Show help" })

  vim.keymap.set("n", "<leader>t", function()
    if not (M.diagram_state and M.diagram_state.source_bufnr) then
      print("Error: Could not find source buffer for the diagram.")

      return
    end

    print("Starting E2E test from diagram...")

    tester.run({ source_bufnr = M.diagram_state.source_bufnr })
  end, { buffer = buf, silent = false, desc = "Run E2E Test" })

  vim.keymap.set(
    "n",
    "<leader>te",
    M.edit_override_file,
    { buffer = buf, silent = false, desc = "Edit Test Override File" }
  )

  if state.type == "horizontal" then
    vim.keymap.set("n", "<leader>k", function()
      M.close_component_popup()

      local _, box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)

      if box then
        state.popup_win_id = M.open_component_popup(box, {

          parent_win_id = state.win_id,

          layout = "horizontal_manual",
        })
      end
    end, { buffer = buf, silent = true, desc = "Show component code/diff" })
  else -- vertical_list
    vim.keymap.set("n", "<leader>k", function()
      M.close_component_popup()

      local _, box = M.get_box_at_cursor(state.win_id, state.box_metadata, state.type)

      if box then
        state.popup_win_id = M.open_component_popup(box)
      end
    end, { buffer = buf, silent = true, desc = "Show component code" })

    vim.keymap.set("n", "o", M.add_component_from_diagram, { buffer = buf, silent = false, desc = "Add new component" })
  end
end

-- ===================================================================

-- Diagram Creation

-- ===================================================================

local function _on_diagram_win_closed(win_id)
  M.close_component_popup()

  M.close_help_popup()

  if M.diagram_state and M.diagram_state.win_id == win_id then
    if M.diagram_state.source_bufnr and vim.api.nvim_buf_is_valid(M.diagram_state.source_bufnr) then
      vim.api.nvim_buf_clear_namespace(M.diagram_state.source_bufnr, ns_id_dim, 0, -1)
    end

    vim.api.nvim_buf_clear_namespace(M.diagram_state.buf, ns_id_results, 0, -1)

    M.diagram_state = nil

    integration_state.last_summary_data = nil
  end
end

function M.CreatePipelineDiagram(opts)
  opts = opts or {}

  vim.notify("🚀 Creating pipeline diagram...")

  --- PERFORMANCE: Defer the entire creation to make the UI responsive.

  vim.schedule(function()
    tester.update_override_state()

    M.show_override_icons_in_buffer()

    local focus_key = opts.focus_key

    local source_bufnr = vim.api.nvim_get_current_buf()

    if M.diagram_state and M.diagram_state.win_id and vim.api.nvim_win_is_valid(M.diagram_state.win_id) then
      vim.api.nvim_win_close(M.diagram_state.win_id, true)
    end

    M.diagram_state = nil

    local components, all_chains_by_key, _ = _get_parsed_pipeline_data(source_bufnr)

    if not components or not all_chains_by_key then
      vim.notify("Could not analyze pipeline.", vim.log.levels.WARN)

      return
    end

    local groups = M.GetPipelineSteps(source_bufnr)

    if groups == nil or vim.tbl_isempty(groups) then
      vim.notify("No pipelines found to visualize.", vim.log.levels.WARN)

      return
    end

    _setup_highlights()

    local arrow_chars =
      
{ h = "─", v = "│", bl = "└", br = "┘", tr = "┐", arrow = "►", up = "▲", down = "▼" }

    local arrow = " " .. string.rep(arrow_chars.h, 2) .. arrow_chars.arrow .. " "

    local final_content, box_metadata, drawn_node_coords = {}, {}, {}

    local sorted_group_keys = {}

    for k in pairs(groups) do
      table.insert(sorted_group_keys, k)
    end

    table.sort(sorted_group_keys)

    for group_idx, key in ipairs(sorted_group_keys) do
      local group = groups[key]

      local function center(text, width)
        local text_width = vim.fn.strwidth(text)

        if text_width >= width then
          return text
        end

        local padding_total = width - text_width

        local padding_left = math.floor(padding_total / 2)

        local padding_right = math.ceil(padding_total / 2)

        return string.rep(" ", padding_left) .. text .. string.rep(" ", padding_right)
      end

      local max_text_widths = {}

      local icon_part_width = 4

      for _, chain in ipairs(group) do
        for j, box_data in ipairs(chain) do
          local text_width = math.max(vim.fn.strwidth(box_data.original_type), vim.fn.strwidth(box_data.original_label))

          max_text_widths[j] = math.max(max_text_widths[j] or 0, text_width)
        end
      end

      local max_screen_widths = {}

      for j, text_width in ipairs(max_text_widths) do
        max_screen_widths[j] = icon_part_width + 1 + (text_width + 2)
      end

      for i, chain_data in ipairs(group) do
        local top_parts, type_parts, name_parts, bottom_parts = {}, {}, {}, {}

        local margin_str = string.rep(" ", 2)

        table.insert(top_parts, margin_str)

        table.insert(type_parts, margin_str)

        table.insert(name_parts, margin_str)

        table.insert(bottom_parts, margin_str)

        local current_byte_col = vim.fn.strwidth(margin_str)

        local row_start_line = #final_content + 1

        if i > 1 then
          local parent_box_width = max_screen_widths[1]

          local gap_width = vim.fn.strwidth(arrow)

          local indent_width = parent_box_width + gap_width

          local center_col_of_parent = math.floor(parent_box_width / 2)

          local line1_content = string.rep(" ", center_col_of_parent) .. arrow_chars.v

          local h_line_len = indent_width - center_col_of_parent - 1 - 2

          if h_line_len < 0 then
            h_line_len = 0
          end

          local line2_content = string.rep(" ", center_col_of_parent)
            .. arrow_chars.bl
            .. string.rep(arrow_chars.h, h_line_len)
            .. arrow_chars.arrow
            .. " "

          table.insert(top_parts, line1_content .. string.rep(" ", indent_width - vim.fn.strwidth(line1_content)))

          table.insert(type_parts, line2_content)

          table.insert(name_parts, string.rep(" ", indent_width))

          table.insert(bottom_parts, string.rep(" ", indent_width))

          current_byte_col = current_byte_col + indent_width
        end

        for j = (i == 1 and 1 or 2), #chain_data do
          local box_data = chain_data[j]

          local box_key = box_data.key

          if drawn_node_coords[box_key] then
            local target_coords = drawn_node_coords[box_key]

            local distance = target_coords.start_col - current_byte_col

            if distance < 2 then
              distance = 2
            end

            local h_line = string.rep(arrow_chars.h, distance - 2)

            local type_part_base = " " .. h_line

            local type_part, blank_merge_space, top_part, bottom_part

            if target_coords.line < row_start_line then
              type_part = type_part_base .. arrow_chars.br

              top_part = string.rep(" ", distance - 1) .. arrow_chars.up

              bottom_part = string.rep(" ", distance)
            else
              type_part = type_part_base .. arrow_chars.tr

              top_part = string.rep(" ", distance)

              bottom_part = string.rep(" ", distance - 1) .. arrow_chars.down
            end

            blank_merge_space = string.rep(" ", distance)

            table.insert(top_parts, top_part)

            table.insert(type_parts, type_part)

            table.insert(name_parts, blank_merge_space)

            table.insert(bottom_parts, bottom_part)

            current_byte_col = current_byte_col + distance

            break
          end

          local process_name = box_data.original_type:match("%.([^.]+)$") or box_data.original_type

          local icon = process_icons[process_name] or process_icons.default

          local text_part_width = max_text_widths[j]

          local is_overridden =
            integration_state.overridden_components[box_data.original_type .. "-" .. box_data.original_label]

          local centered_type = center(box_data.original_type, text_part_width)

          local centered_label = center(box_data.original_label, text_part_width)

          local centered_icon = center(icon, icon_part_width - 2)

          local icon_col_2_content = is_overridden and center("🧪", icon_part_width)
            or string.rep(" ", icon_part_width)

          local text_padding = string.rep("─", text_part_width + 2)

          local icon_padding = string.rep("─", icon_part_width)

          local t_part = "┌" .. icon_padding .. "┬" .. text_padding .. "┐"

          local l1_part = "│ " .. centered_icon .. " │ " .. centered_type .. " │"

          local l2_part = "│" .. icon_col_2_content .. "│ " .. centered_label .. " │"

          local b_part = "└" .. icon_padding .. "┴" .. text_padding .. "┘"

          table.insert(top_parts, t_part)

          table.insert(type_parts, l1_part)

          table.insert(name_parts, l2_part)

          table.insert(bottom_parts, b_part)

          local box_byte_length = #l1_part

          table.insert(box_metadata, {

            key = box_data.key,

            label = box_data.original_label,

            line_in_diagram = row_start_line,

            start_col = current_byte_col,

            end_col = current_byte_col + box_byte_length - 1,

            source_line = box_data.source_line,

            color = box_data.color,

            original_type = box_data.original_type,

            original_label = box_data.original_label,

            content = box_data.content,

            original_block_content = box_data.original_block_content,

            is_overridden = is_overridden,
          })

          drawn_node_coords[box_key] = { line = row_start_line, start_col = current_byte_col }

          current_byte_col = current_byte_col + box_byte_length

          if j < #chain_data then
            local next_box_key = chain_data[j + 1].key

            if not drawn_node_coords[next_box_key] then
              local arrow_space = string.rep(" ", vim.fn.strwidth(arrow))

              table.insert(top_parts, arrow_space)

              table.insert(type_parts, arrow)

              table.insert(name_parts, arrow_space)

              table.insert(bottom_parts, arrow_space)

              current_byte_col = current_byte_col + #arrow
            end
          end
        end

        table.insert(final_content, table.concat(top_parts))

        table.insert(final_content, table.concat(type_parts))

        table.insert(final_content, table.concat(name_parts))

        table.insert(final_content, table.concat(bottom_parts))
      end

      if group_idx < #sorted_group_keys then
        table.insert(final_content, "")
      end
    end

    if #final_content == 0 then
      vim.notify("No pipelines found to visualize.", vim.log.levels.WARN)

      return
    end

    local diagram_height = #final_content

    local container_height = diagram_height + 2

    local container_buf = vim.api.nvim_create_buf(false, true)

    vim.bo[container_buf].buftype = "nofile"

    local container_win_id = M.create_top_split_window(container_buf, container_height)

    vim.wo[container_win_id].winhighlight = "Normal:Comment"

    --- BUGFIX: Add keymap to close container with 'q'

    vim.keymap.set("n", "q", function()
      vim.api.nvim_win_close(container_win_id, true)
    end, { buffer = container_buf, silent = true, nowait = true })

    local diagram_buf = vim.api.nvim_create_buf(false, true)

    vim.bo[diagram_buf].filetype = "alloy_horizontal_diagram"

    vim.api.nvim_buf_set_lines(diagram_buf, 0, -1, false, final_content)

    local diagram_width = 0

    for _, line in ipairs(final_content) do
      diagram_width = math.max(diagram_width, vim.fn.strwidth(line))
    end

    local float_win_id = M.create_styled_popup(diagram_buf, "Pipeline Diagram", diagram_width, diagram_height, {

      relative = "win",

      win = container_win_id,
    })

    M.diagram_state = {

      win_id = float_win_id,

      container_win_id = container_win_id,

      original_container_height = container_height,

      buf = diagram_buf,

      box_metadata = box_metadata,

      source_bufnr = source_bufnr,

      type = "horizontal",

      popup_win_id = nil,

      help_popup_win_id = nil,

      pipelines = all_chains_by_key,

      components = components,

      nav_mode = "pipeline",

      focused_pipeline_index = nil,

      total_content_width = diagram_width,
    }

    vim.api.nvim_create_autocmd("WinClosed", {

      pattern = tostring(float_win_id),

      once = true,

      callback = function()
        _on_diagram_win_closed(float_win_id)

        if vim.api.nvim_win_is_valid(container_win_id) then
          vim.api.nvim_win_close(container_win_id, true)
        end
      end,
    })

    vim.api.nvim_create_autocmd("WinClosed", {

      pattern = tostring(container_win_id),

      once = true,

      callback = function()
        if vim.api.nvim_win_is_valid(float_win_id) then
          vim.api.nvim_win_close(float_win_id, true)
        end
      end,
    })

    vim.defer_fn(function()
      if not vim.api.nvim_buf_is_valid(diagram_buf) then
        return
      end

      local line_to_color_hl = {}

      for _, box in ipairs(box_metadata) do
        local hl = "DiagramBox" .. (box.color or "Storm")

        for i = 0, 3 do
          line_to_color_hl[box.line_in_diagram + i] = hl
        end
      end

      for i, line_content in ipairs(final_content) do
        local line_idx = i - 1

        local connector_hl = line_to_color_hl[i] or "DiagramBoxTreeConnector"

        local offset = 1

        while true do
          local arrow_start, arrow_end = line_content:find(arrow, offset, true)

          if not arrow_start then
            break
          end

          vim.api.nvim_buf_add_highlight(diagram_buf, -1, "DiagramArrow", line_idx, arrow_start - 1, arrow_end)

          offset = arrow_end + 1
        end

        offset = 1

        while offset <= #line_content do
          local s, e =
            
string.find(line_content, "[└┘┐┌│─┬┴═▲▼" .. arrow_chars.arrow .. "]", offset)

          if not s then
            break
          end

          vim.api.nvim_buf_add_highlight(diagram_buf, -1, connector_hl, line_idx, s - 1, e)

          offset = e + 1
        end
      end
    end, 50)

    vim.api.nvim_create_autocmd("WinLeave", {

      buffer = diagram_buf,

      callback = function()
        if

          M.diagram_state
          and M.diagram_state.source_bufnr
          and vim.api.nvim_buf_is_valid(M.diagram_state.source_bufnr)
        then
          vim.api.nvim_buf_clear_namespace(M.diagram_state.source_bufnr, ns_id_dim, 0, -1)
        end
      end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {

      buffer = diagram_buf,

      callback = function()
        vim.schedule(M.FollowFromDiagram)
      end,
    })

    _setup_diagram_keymaps()

    --- BUGFIX: Defer the focus logic until after the window is fully drawn.

    if focus_key and M.diagram_state then
      vim.schedule(function()
        if not M.diagram_state then
          return
        end

        local state = M.diagram_state

        local target_pipeline_index = nil

        for i, pipeline in ipairs(state.pipelines) do
          if vim.tbl_contains(pipeline, focus_key) then
            target_pipeline_index = i

            break
          end
        end

        local target_box = nil

        for _, box in ipairs(state.box_metadata) do
          if box.key == focus_key then
            target_box = box

            break
          end
        end

        if target_pipeline_index and target_box then
          state.nav_mode = "component"

          state.focused_pipeline_index = target_pipeline_index

          print("Pipeline focused. Navigation: Jumping between components.")

          local start_node_key = state.pipelines[target_pipeline_index][1]

          local keys_in_group = {}

          for _, chain in ipairs(state.pipelines) do
            if #chain > 0 and chain[1] == start_node_key then
              for _, key in ipairs(chain) do
                keys_in_group[key] = true
              end
            end
          end

          local min_line, max_line = 9999, 0

          for _, box in ipairs(state.box_metadata) do
            if keys_in_group[box.key] then
              min_line = math.min(min_line, box.line_in_diagram)

              max_line = math.max(max_line, box.line_in_diagram)
            end
          end

          if min_line <= max_line then
            local content_height = (max_line - min_line) + 4

            local new_container_height = content_height + 2

            if state.container_win_id and vim.api.nvim_win_is_valid(state.container_win_id) then
              vim.api.nvim_win_set_height(state.container_win_id, new_container_height)

              vim.api.nvim_win_set_config(state.win_id, { height = content_height })
            end
          end

          local win_id = state.win_id

          if state.type == "horizontal" then
            local view = vim.fn.winsaveview()

            local win_width = vim.api.nvim_win_get_width(win_id)

            if state.total_content_width > win_width then
              local max_leftcol = state.total_content_width - win_width

              local box_center_col = target_box.start_col + math.floor((target_box.end_col - target_box.start_col) / 2)

              local desired_leftcol = box_center_col - math.floor(win_width / 2)

              view.leftcol = math.max(0, math.min(desired_leftcol, max_leftcol))
            else
              view.leftcol = 0
            end

            vim.fn.winrestview(view)
          end

          local line = target_box.line_in_diagram + 1

          local col = target_box.start_col + 2

          vim.api.nvim_win_set_cursor(win_id, { line, col })

          vim.fn.win_execute(win_id, "normal! zz")

          local source_win_id = vim.fn.bufwinid(state.source_bufnr)

          if source_win_id ~= -1 then
            local original_scrolloff = vim.api.nvim_win_get_option(source_win_id, "scrolloff")

            vim.api.nvim_win_set_option(source_win_id, "scrolloff", 0)

            vim.api.nvim_win_set_cursor(source_win_id, { target_box.source_line, 0 })

            vim.fn.win_execute(source_win_id, "normal! zt")

            vim.api.nvim_win_set_option(source_win_id, "scrolloff", original_scrolloff)
          end
        end
      end)
    else
      M.FollowComponentInDiagram()
    end
  end)
end

--- FEATURE: Add component scaffolding from vertical diagram

function M.add_component_from_diagram()
  if not (M.diagram_state and M.diagram_state.type == "vertical_list") then
    return
  end

  local _, box_before = M.get_box_at_cursor(M.diagram_state.win_id, M.diagram_state.box_metadata, M.diagram_state.type)

  if not box_before then
    vim.notify("Cursor must be on a component to add a new one after it.", vim.log.levels.WARN)

    return
  end

  vim.ui.input({ prompt = 'New component (e.g., loki.process "my_stage"): ' }, function(input)
    if not input or input == "" then
      return
    end

    local new_type, new_label = input:match('^([%w_%.]+)%s*"?([%w_%.]+)"?$')

    if not (new_type and new_label) then
      vim.notify('Invalid component format. Use: <type> "<label>"', vim.log.levels.ERROR)

      return
    end

    local source_bufnr = M.diagram_state.source_bufnr

    local components, _, _ = _get_parsed_pipeline_data(source_bufnr)

    if not components then
      return
    end

    local insert_at_line = components[box_before.key].end_line

    local boilerplate = { "", "", new_type .. ' "' .. new_label .. '" {' .. "}" }

    vim.api.nvim_buf_set_lines(source_bufnr, insert_at_line, insert_at_line, false, boilerplate)

    local source_win = vim.fn.bufwinid(source_bufnr)

    if source_win ~= -1 then
      vim.api.nvim_set_current_win(source_win)

      vim.api.nvim_win_set_cursor(source_win, { insert_at_line + 3, 0 })
    end

    vim.notify(
      "Boilerplate for '" .. new_type .. ' "' .. new_label .. '"' .. "' inserted. Please wire up connections.",
      vim.log.levels.INFO
    )

    M.CreateVerticalPipelineDiagram() -- Refresh the diagram
  end)
end

function M.CreateVerticalPipelineDiagram(filter_word)
  tester.update_override_state()

  M.show_override_icons_in_buffer()

  vim.notify("🚀 Creating vertical diagram...")

  vim.schedule(function()
    if M.diagram_state and M.diagram_state.win_id and vim.api.nvim_win_is_valid(M.diagram_state.win_id) then
      vim.api.nvim_win_close(M.diagram_state.win_id, true)
    end

    local source_bufnr = vim.api.nvim_get_current_buf()

    _setup_highlights()

    local components, all_chains_by_key, _ = _get_parsed_pipeline_data(source_bufnr)

    if not components or not all_chains_by_key then
      vim.notify("Could not analyze pipeline.", vim.log.levels.WARN)

      return
    end

    local filter_lower = (filter_word and filter_word ~= "") and filter_word:lower() or nil

    local chains_to_render = all_chains_by_key

    if filter_lower then
      local filtered = {}

      for _, chain in ipairs(all_chains_by_key) do
        local matches = false

        for _, key in ipairs(chain) do
          if

            components[key]
            and (components[key].label:lower():find(filter_lower) or components[key].type:lower():find(filter_lower))
          then
            matches = true

            break
          end
        end

        if matches then
          table.insert(filtered, chain)
        end
      end

      chains_to_render = filtered
    end

    if #chains_to_render == 0 then
      vim.notify(
        filter_word and ("No pipelines match filter: '" .. filter_word .. "'") or "No pipelines found.",
        vim.log.levels.WARN
      )

      return
    end

    local output = { lines = {}, metadata = {} }

    if filter_lower then
      local filter_content = " " .. filter_word

      table.insert(output.lines, "╭─ " .. filter_content .. " ─╮")
    else
      table.insert(output.lines, " [No Filter] ")
    end

    table.insert(output.lines, "")

    for i, chain in ipairs(chains_to_render) do
      if i > 1 then
        table.insert(output.lines, "")
      end

      table.insert(output.lines, string.format("--- Pipeline Branch %d ---", i))

      for _, key in ipairs(chain) do
        local comp = components[key]

        if comp then
          local is_match = filter_lower
            and (comp.label:lower():find(filter_lower) or comp.type:lower():find(filter_lower))

          local line_prefix = is_match and "▶" or " "

          local process_name = comp.type:match("%.([^.]+)$") or comp.type

          local icon = process_icons[process_name] or process_icons.default

          local children = comp.forward_to or {}

          local parents = comp.receives_from or {}

          local is_overridden = integration_state.overridden_components[comp.type .. "-" .. comp.label]

          local type_text = comp.type .. (is_overridden and " 🧪" or "")

          local line_text = string.format("%s %s %s (%s)", line_prefix, icon, type_text, comp.label)

          local indicators = {}

          if #parents > 1 then
            table.insert(indicators, " merging")
          end

          if #children > 1 then
            table.insert(indicators, " forking")
          end

          if #indicators > 0 then
            line_text = line_text .. " " .. table.concat(indicators, " ")
          end

          table.insert(output.lines, line_text)

          table.insert(output.metadata, {

            key = key,

            line_in_diagram = #output.lines,

            source_line = comp.line,

            original_type = comp.type,

            original_label = comp.label,

            content = comp.content,

            icon = icon,

            is_filter_match = is_match,

            is_overridden = is_overridden,

            original_block_content = comp.original_block_content,
          })
        end
      end
    end

    local margin_str = string.rep(" ", 2)

    for i, line in ipairs(output.lines) do
      output.lines[i] = margin_str .. line
    end

    local max_width = 0

    for _, line in ipairs(output.lines) do
      max_width = math.max(max_width, vim.fn.strwidth(line))
    end

    local unpadded_filter_line = output.lines[1]

    local padding = max_width - vim.fn.strwidth(unpadded_filter_line)

    if padding > 0 then
      local pad_left = math.floor(padding / 2)

      local pad_right = padding - pad_left

      output.lines[1] = string.rep(" ", pad_left) .. unpadded_filter_line .. string.rep(" ", pad_right)
    end

    local win_width = math.min(max_width + 4, 100)

    local buf = vim.api.nvim_create_buf(false, true)

    vim.bo[buf].filetype = "alloy_vertical_diagram"

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output.lines)

    vim.cmd("rightbelow vsplit")

    local win_id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_config(win_id, { title = "Vertical Pipeline", title_pos = "center" })

    vim.api.nvim_win_set_buf(win_id, buf)

    vim.api.nvim_win_set_width(win_id, win_width)

    vim.wo[win_id].cursorline = true

    vim.wo[win_id].number = false

    vim.wo[win_id].relativenumber = false

    vim.wo[win_id].signcolumn = "no"

    vim.wo[win_id].list = false

    vim.wo[win_id].spell = false

    vim.defer_fn(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      local line_to_meta = {}

      for _, meta in ipairs(output.metadata) do
        line_to_meta[meta.line_in_diagram] = meta
      end

      for i, line in ipairs(output.lines) do
        if i == 1 then
          local hl_group = filter_lower and "DiagramBoxFilter" or "DiagramBoxFilterInactive"

          vim.api.nvim_buf_add_highlight(buf, -1, hl_group, i - 1, 0, -1)
        elseif line:match("^---") then
          vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxStageHeader", i - 1, 0, -1)
        elseif line_to_meta[i] then
          local meta = line_to_meta[i]

          local comp = components[meta.key]

          if comp then
            local offset = vim.fn.strwidth("▶ ") + vim.fn.strwidth(margin_str)

            local icon_bytes = #meta.icon

            vim.api.nvim_buf_add_highlight(
              buf,
              -1,
              "DiagramBox" .. (comp.color or "Storm"),
              i - 1,
              offset,
              offset + icon_bytes + 1
            )

            vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxComponentBaseText", i - 1, offset + icon_bytes + 1, -1)

            local type_s, type_e = line:find(comp.type, offset + icon_bytes + 2, true)

            if type_s then
              vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxComponentTypeBold", i - 1, type_s - 1, type_e)
            end

            local label_s, label_e = line:find("(" .. comp.label .. ")", (type_e or (offset + icon_bytes)) + 1, true)

            if label_s then
              vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxComponentLabelDim", i - 1, label_s - 1, label_e)
            end

            local merge_s, merge_e = line:find(" merging", 1, true)

            if merge_s then
              vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxBranchIcon", i - 1, merge_s - 1, merge_e)
            end

            local fork_s, fork_e = line:find(" forking", 1, true)

            if fork_s then
              vim.api.nvim_buf_add_highlight(buf, -1, "DiagramBoxBranchIcon", i - 1, fork_s - 1, fork_e)
            end
          end
        end
      end
    end, 50)

    M.diagram_state = {

      win_id = win_id,

      buf = buf,

      box_metadata = output.metadata,

      source_bufnr = source_bufnr,

      type = "vertical_list",

      popup_win_id = nil,

      help_popup_win_id = nil,

      pipelines = chains_to_render,

      components = components,

      nav_mode = "pipeline",

      focused_pipeline_index = nil,
    }

    _setup_diagram_keymaps()

    vim.keymap.set("n", "f", function()
      vim.ui.input({ prompt = "Filter by component label or type: " }, function(input)
        if input and input ~= "" then
          M.CreateVerticalPipelineDiagram(input)
        end
      end)
    end, { buffer = buf, silent = true, desc = "Filter diagram" })

    vim.keymap.set("n", "<S-f>", function()
      local _, box = M.get_box_at_cursor(win_id, output.metadata, "vertical_list")

      if box and box.original_label then
        M.CreateVerticalPipelineDiagram(box.original_label)
      end
    end, { buffer = buf, silent = true, desc = "Filter by current component" })

    vim.keymap.set("n", "c", function()
      M.CreateVerticalPipelineDiagram(nil)
    end, { buffer = buf, silent = true, desc = "Clear filter" })

    vim.api.nvim_create_autocmd("WinClosed", {

      pattern = tostring(win_id),

      once = true,

      callback = function()
        _on_diagram_win_closed(win_id)
      end,
    })

    vim.api.nvim_create_autocmd("WinLeave", {

      buffer = buf,

      callback = function()
        if

          M.diagram_state
          and M.diagram_state.source_bufnr
          and vim.api.nvim_buf_is_valid(M.diagram_state.source_bufnr)
        then
          vim.api.nvim_buf_clear_namespace(M.diagram_state.source_bufnr, ns_id_dim, 0, -1)
        end
      end,
    })

    local follow_timer_diagram = nil

    local function debounced_follow_from_diagram()
      if follow_timer_diagram then
        follow_timer_diagram:close()
      end

      follow_timer_diagram = vim.loop.new_timer()

      follow_timer_diagram:start(50, 0, function()
        vim.schedule(M.FollowFromDiagram)
      end)
    end

    vim.api.nvim_create_autocmd("CursorMoved", { buffer = buf, callback = debounced_follow_from_diagram })

    M.FollowComponentInDiagram()
  end)
end

-- ===================================================================

-- Bidirectional "Follow" & Test Result Functions

-- ===================================================================

function M.update_diagram_with_results(summary_data)
  if not M.diagram_state or not M.diagram_state.win_id or not vim.api.nvim_win_is_valid(M.diagram_state.win_id) then
    return
  end

  local buf = M.diagram_state.buf

  vim.api.nvim_buf_clear_namespace(buf, ns_id_results, 0, -1)

  local result_hl = summary_data.test_passed and "DiagramBoxSuccess" or "DiagramBoxFailure"

  local result_text

  --- IMPROVEMENT: Create a richer feedback string with metrics.

  if summary_data.test_passed then
    result_text = " ✅ Passed"
  else
    local parts = {}

    if #summary_data.missing_logs > 0 then
      table.insert(parts, #summary_data.missing_logs .. " missing")
    end

    if #summary_data.unexpected_logs > 0 then
      table.insert(parts, #summary_data.unexpected_logs .. " unexpected")
    end

    result_text = " ❌ (" .. table.concat(parts, ", ") .. ")"
  end

  for _, box in ipairs(M.diagram_state.box_metadata) do
    if box.original_type:match("write") then
      for i = 0, 3 do
        vim.api.nvim_buf_add_highlight(buf, ns_id_results, result_hl, box.line_in_diagram - 1 + i, 0, -1)
      end

      vim.api.nvim_buf_set_extmark(
        buf,
        ns_id_results,
        box.line_in_diagram,
        -1,
        { virt_text = { { result_text, result_hl } }, virt_text_pos = "eol" }
      )
    end
  end
end

function M.FollowComponentInDiagram()
  if M._is_syncing or not M.diagram_state or not vim.api.nvim_win_is_valid(M.diagram_state.win_id) then
    return
  end

  local components, _, _ = _get_parsed_pipeline_data(M.diagram_state.source_bufnr)

  if not components then
    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local current_component_key = nil

  for key, comp_data in pairs(components) do
    if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
      current_component_key = key

      break
    end
  end

  local diagram_buf = M.diagram_state.buf

  vim.api.nvim_buf_clear_namespace(diagram_buf, ns_id_follow, 0, -1)

  if not current_component_key then
    return
  end

  local target_box = nil

  for _, box in ipairs(M.diagram_state.box_metadata) do
    if box.key == current_component_key then
      target_box = box

      break
    end
  end

  if not target_box then
    return
  end

  local line = (M.diagram_state.type == "horizontal") and (target_box.line_in_diagram + 1) or target_box.line_in_diagram

  local col = (M.diagram_state.type == "horizontal") and (target_box.start_col + 2) or 2

  if M.diagram_state.type == "vertical_list" then
    vim.api.nvim_buf_add_highlight(diagram_buf, ns_id_follow, "DiagramBoxFollow", target_box.line_in_diagram - 1, 0, -1)
  else
    for i = 0, 3 do
      vim.api.nvim_buf_add_highlight(
        diagram_buf,
        ns_id_follow,
        "DiagramBoxFollow",
        target_box.line_in_diagram - 1 + i,
        0,
        -1
      )
    end
  end

  M._is_syncing = true

  vim.api.nvim_win_set_cursor(M.diagram_state.win_id, { line, col })

  vim.fn.win_execute(M.diagram_state.win_id, "normal! zz")

  M._is_syncing = false
end

function M.FollowFromDiagram()
  if M._is_syncing or not M.diagram_state or vim.api.nvim_get_current_win() ~= M.diagram_state.win_id then
    return
  end

  local source_bufnr = M.diagram_state.source_bufnr

  local _, current_box = M.get_box_at_cursor(M.diagram_state.win_id, M.diagram_state.box_metadata, M.diagram_state.type)

  vim.api.nvim_buf_clear_namespace(M.diagram_state.buf, ns_id_follow, 0, -1)

  if current_box then
    if M.diagram_state.type == "vertical_list" then
      vim.api.nvim_buf_add_highlight(
        M.diagram_state.buf,
        ns_id_follow,
        "DiagramBoxFollow",
        current_box.line_in_diagram - 1,
        0,
        -1
      )
    else
      for i = 0, 3 do
        vim.api.nvim_buf_add_highlight(
          M.diagram_state.buf,
          ns_id_follow,
          "DiagramBoxFollow",
          current_box.line_in_diagram - 1 + i,
          0,
          -1
        )
      end
    end

    local source_win_id = vim.fn.bufwinid(source_bufnr)

    if source_win_id ~= -1 then
      M._is_syncing = true

      local original_scrolloff = vim.api.nvim_win_get_option(source_win_id, "scrolloff")

      vim.api.nvim_win_set_option(source_win_id, "scrolloff", 0)

      vim.api.nvim_win_set_cursor(source_win_id, { current_box.source_line, 0 })

      vim.fn.win_execute(source_win_id, "normal! zt")

      vim.api.nvim_win_set_option(source_win_id, "scrolloff", original_scrolloff)

      M._is_syncing = false
    end
  end

  if not current_box then
    vim.api.nvim_buf_clear_namespace(source_bufnr, ns_id_dim, 0, -1)

    M.close_component_popup()

    return
  end

  vim.api.nvim_buf_clear_namespace(source_bufnr, ns_id_dim, 0, -1)

  local components, _, _ = _get_parsed_pipeline_data(source_bufnr)

  if not components then
    return
  end

  local current_key = current_box.key

  for key, comp_data in pairs(components) do
    if key ~= current_key then
      for line_num = comp_data.line - 1, comp_data.end_line - 1 do
        vim.api.nvim_buf_add_highlight(source_bufnr, ns_id_dim, "DiagramDimmedText", line_num, 0, -1)
      end
    end
  end

  M.close_component_popup()
end

-- ===================================================================

-- Setup and Exposed Functions

-- ===================================================================

function M.setup_keymaps()
  integration_state.visualizer_module = M

  local follow_timer = nil

  local function debounced_follow_from_source()
    if M._is_syncing or not M.diagram_state or vim.api.nvim_get_current_buf() ~= M.diagram_state.source_bufnr then
      return
    end

    if follow_timer then
      follow_timer:close()
    end

    follow_timer = vim.loop.new_timer()

    follow_timer:start(150, 0, function()
      vim.schedule(M.FollowComponentInDiagram)
    end)
  end

  local group = vim.api.nvim_create_augroup("AlloyPipelineKeymaps", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {

    pattern = "alloy",

    group = group,

    callback = function(args)
      local mappings = {

        { "n", "]a", M.JumpToNextComponent, "Alloy: Jump to Next Pipeline Component" },

        { "n", "[a", M.JumpToPreviousComponent, "Alloy: Jump to Previous Pipeline Component" },

        { "n", "]b", M.JumpToNextBlockInFile, "Alloy: Jump to Next Block in File" },

        { "n", "[b", M.JumpToPreviousBlockInFile, "Alloy: Jump to Previous Block in File" },

        { "n", "<leader>te", M.edit_override_file, "Alloy: Edit Test Override file" },

        { "n", "<leader>toi", M.show_override_icons_in_buffer, "Alloy: Show Test Override Icons" },

        { "n", "<leader>toI", M.clear_override_icons_in_buffer, "Alloy: Clear Test Override Icons" },

        { "n", "<leader>k", M.show_diff_popup_from_buffer, "Alloy: Show Override Diff" },

        { "n", "<C-j>", tester.jump_to_test_window, "Alloy: Jump to Test Log" },
      }

      for _, map in ipairs(mappings) do
        local mode, lhs, rhs, desc = unpack(map)

        vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc, silent = true })
      end

      vim.keymap.set("n", "gp", function()
        local source_bufnr = vim.api.nvim_get_current_buf()

        local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

        local components, _, _ = _get_parsed_pipeline_data(source_bufnr)

        local focus_key = nil

        if components then
          for key, comp_data in pairs(components) do
            if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
              focus_key = key

              break
            end
          end
        end

        M.CreatePipelineDiagram({ focus_key = focus_key })
      end, { buffer = args.buf, desc = "Alloy: Show/Focus Pipeline Diagram (Horizontal)", silent = true })

      vim.keymap.set("n", "p", function()
        local source_bufnr = vim.api.nvim_get_current_buf()

        local components, _, _ = _get_parsed_pipeline_data(source_bufnr)

        local current_component_label = nil

        if components then
          local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

          for _, comp_data in pairs(components) do
            if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
              current_component_label = comp_data.label

              break
            end
          end
        end

        M.CreateVerticalPipelineDiagram(current_component_label)
      end, { buffer = args.buf, desc = "Alloy: Show/Focus Pipeline Diagram (Vertical)" })

      vim.api.nvim_create_autocmd("CursorMoved", { buffer = args.buf, callback = debounced_follow_from_source })

      vim.api.nvim_create_autocmd("BufEnter", {

        buffer = args.buf,

        callback = function()
          vim.defer_fn(M.show_override_icons_in_buffer, 100)
        end,
      })
    end,
  })
end

function M.ClearPipelineNumbers()
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

  print("Cleared pipeline icons.")
end

function M.FoldUnrelatedPipelines()
  local current_buf = vim.api.nvim_get_current_buf()

  local components, all_chains_by_key, _ = _get_parsed_pipeline_data(current_buf)

  if not components or not all_chains_by_key then
    print("Could not analyze pipelines to fold.")

    return
  end

  local original_cursor = vim.api.nvim_win_get_cursor(0)

  local cursor_line = original_cursor[1]

  local current_component_key = nil

  for key, comp_data in pairs(components) do
    if cursor_line >= comp_data.line and cursor_line <= comp_data.end_line then
      current_component_key = key

      break
    end
  end

  if not current_component_key then
    print("Cursor is not inside a component block.")

    return
  end

  local relevant_component_keys = {}

  if all_chains_by_key then
    for _, chain in ipairs(all_chains_by_key) do
      if vim.tbl_contains(chain, current_component_key) then
        for _, key_in_chain in ipairs(chain) do
          relevant_component_keys[key_in_chain] = true
        end
      end
    end
  end

  vim.cmd("setlocal foldmethod=manual")

  vim.cmd("normal! zR")

  local folded_count = 0

  for key, comp_data in pairs(components) do
    if not relevant_component_keys[key] then
      vim.api.nvim_command(string.format("%d,%dfold", comp_data.line, comp_data.end_line))

      folded_count = folded_count + 1
    end
  end

  vim.api.nvim_win_set_cursor(0, original_cursor)

  if folded_count > 0 then
    print(string.format("Folded %d unrelated component(s).", folded_count))
  end
end

function M.FocusPipeline()
  M.ShowPipelineNumbers()

  M.FoldUnrelatedPipelines()
end

return M
