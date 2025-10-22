-- ==============================================================================
-- Alloy End-to-End Test Script (Lua for Neovim)
-- ==============================================================================

local M = {}

--- INTEGRATION: Require the shared state module to communicate with the visualizer.
local integration_state = require("functions.alloy_integration_state")

-- --- Configuration & State ---
local config = {
  loki_url = "http://localhost:3100",
  manage_loki = true,
  loki_container_name = "neovim-loki-test",
  loki_image = "grafana/loki:3.0.0",
  override_dir_name = ".alloy_tests", -- Directory in project root for all test files
}

local state = {
  test_dir = nil,
  alloy_data_dir = nil,
  alloy_pid = nil,
  alloy_port = nil,
  output_buf = nil,
  output_win = nil,
  loki_started_by_script = false,
  last_summary_data = nil,
  summary_win_id = nil,
  last_alloy_config_content = nil,
  diff_ns_id = nil,
  source_win_id = nil,
  last_source_bufnr = nil,
}

-- --- Helper Functions ---

--- UX: Helper for creating styled popups, consistent with visualizer.
local function create_styled_popup(buf, title, width, height, opts)
  opts = opts or {}
  local win_opts = {
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    width = width,
    height = height,
    zindex = 100,
  }

  for k, v in pairs(opts) do
    win_opts[k] = v
  end

  win_opts.relative = "editor"
  win_opts.row = win_opts.row or math.floor((vim.o.lines - height - 2) / 2)
  win_opts.col = win_opts.col or math.floor((vim.o.columns - width - 2) / 2)

  local win_id = vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_set_hl(0, "HelpFloatBorder", { fg = "#5E81AC" })
  vim.api.nvim_set_hl(0, "HelpFloatTitle", { fg = "#EBCB8B", bold = true })
  vim.api.nvim_win_set_option(win_id, "winhl", "Normal:Normal,FloatBorder:HelpFloatBorder,Title:HelpFloatTitle")
  return win_id
end

--- UX: Help window now uses the standardized styled popup.
local function show_help_window()
  local help_content = {
    "This script runs an E2E test by replacing Alloy blocks",
    "from your buffer with overrides found in the `.alloy_tests`",
    "directory.",
    "",
    "Keymaps in this Log Window:",
    "• q:         Hide this log window.",
    "• <C-k>:     Jump back to the source code window.",
    "• g?:        Show this help popup.",
    "",
    "Global Keymaps (in .alloy files):",
    "• <leader>tar: Run test from current buffer.",
    "• <leader>taR: Rerun the last test exactly.",
    "• <leader>tas: Toggle the last test summary report.",
    "• <leader>tal: Toggle visibility of the test log window.",
    "• <C-j>:     Jump from source code to this window (if visible).",
    "",
    "Press 'q' or <Esc> to close this help popup.",
  }

  local max_width = 0
  for _, line in ipairs(help_content) do
    max_width = math.max(max_width, vim.fn.strwidth(line))
  end
  local width = max_width + 4
  local height = #help_content

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_content)

  local win = create_styled_popup(buf, "❓ Test Runner Help", width, height, {})

  local function close_win()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
end

local function find_log_window()
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win_id) then
      local buf_id = vim.api.nvim_win_get_buf(win_id)
      local ok, is_log_buffer = pcall(vim.api.nvim_buf_get_var, buf_id, "is_alloy_test_log_buffer")
      if ok and is_log_buffer then
        return win_id, buf_id
      end
    end
  end
  return nil, nil
end

local function open_log_window(buf_id)
  --- UX FIX: Add horizontal margins to the test log window.
  local margin = math.floor(vim.o.columns * 0.05)
  local width = vim.o.columns - (margin * 2)
  local height = math.floor(vim.o.lines * 0.4)
  local row = vim.o.lines - height - vim.o.cmdheight - 1
  local col = margin

  local win_id = vim.api.nvim_open_win(buf_id, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Alloy Test Runner Log ",
    title_pos = "left",
    zindex = 40,
  })
  state.output_win = win_id
end

--- FEATURE: Test log window is now a toggle.
function M.toggle_test_log_window()
  local win_id, _ = find_log_window()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
  else
    if state.output_buf and vim.api.nvim_buf_is_valid(state.output_buf) then
      open_log_window(state.output_buf)
    else
      vim.notify("No active test log to show.", vim.log.levels.WARN)
    end
  end
end

--- FEATURE: Jump-to-window functions
function M.jump_to_test_window()
  --- BUGFIX: Jump to summary window if it is open.
  if state.summary_win_id and vim.api.nvim_win_is_valid(state.summary_win_id) then
    vim.api.nvim_set_current_win(state.summary_win_id)
    return
  end

  local win_id, _ = find_log_window()
  --- BUGFIX: Only jump if window is already visible.
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_set_current_win(win_id)
  else
    vim.notify("Test log window is not visible.", vim.log.levels.INFO)
  end
end

local function jump_to_source_window()
  if state.source_win_id and vim.api.nvim_win_is_valid(state.source_win_id) then
    vim.api.nvim_set_current_win(state.source_win_id)
  else
    integration_state.notify_debug("Source window not found or was closed.", vim.log.levels.WARN)
  end
end

local function setup_output_buffer()
  if not (state.output_buf and vim.api.nvim_buf_is_valid(state.output_buf)) then
    local buf_id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_var(buf_id, "is_alloy_test_log_buffer", true)
    vim.bo[buf_id].buftype = "nofile"
    vim.bo[buf_id].swapfile = false
    vim.bo[buf_id].bufhidden = "hide"
    vim.bo[buf_id].filetype = "markdown"
    state.output_buf = buf_id
  end

  open_log_window(state.output_buf)

  vim.api.nvim_buf_set_lines(state.output_buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(state.output_buf, 0, 0, false, { "--- Alloy & Loki Test Results (g? for help) ---" })
  vim.keymap.set("n", "g?", show_help_window, { buffer = state.output_buf, nowait = true })
  vim.keymap.set(
    "n",
    "q",
    M.toggle_test_log_window,
    { buffer = state.output_buf, nowait = true, silent = true, desc = "Hide Test Log" }
  )
  vim.keymap.set(
    "n",
    "<C-k>",
    jump_to_source_window,
    { buffer = state.output_buf, nowait = true, silent = true, desc = "Jump to Source Window" }
  )
end

local function log_message(msg_or_lines, hl_group)
  if not state.output_buf or not vim.api.nvim_buf_is_valid(state.output_buf) then
    print(vim.inspect(msg_or_lines))
    return
  end
  local lines = type(msg_or_lines) == "table" and msg_or_lines or vim.split(tostring(msg_or_lines), "\n")
  local start_line = vim.api.nvim_buf_line_count(state.output_buf)
  vim.api.nvim_buf_set_lines(state.output_buf, -1, -1, false, lines)
  if hl_group then
    for i = 0, #lines - 1 do
      vim.api.nvim_buf_add_highlight(state.output_buf, -1, hl_group, start_line + i, 0, -1)
    end
  end
  local win_id = vim.fn.bufwinid(state.output_buf)
  if win_id ~= -1 then
    vim.api.nvim_win_set_cursor(win_id, { vim.api.nvim_buf_line_count(state.output_buf), 0 })
  end
end

local function print_info(msg)
  log_message("[INFO] " .. msg, "Comment")
end
local function print_success(msg)
  log_message("[SUCCESS] " .. msg, "String")
end
local function print_error(msg)
  log_message("[ERROR] " .. msg, "ErrorMsg")
end
local function print_step(msg)
  log_message("\n--- " .. msg .. " ---", "Title")
end
local function print_code(msg)
  log_message(msg, "Constant")
end
local function print_alloy_log(msg)
  log_message("[ALLOY LOG] " .. msg, "Debug")
end

local function print_code_in_box(title, lines_data)
  local diff_add_bg_color = "#1E2B1E"
  local diff_del_bg_color = "#2B1E1E"
  vim.api.nvim_set_hl(0, "AlloyTestDiffAddBg", { bg = diff_add_bg_color })
  vim.api.nvim_set_hl(0, "AlloyTestDiffDelBg", { fg = "#808080", bg = diff_del_bg_color })
  vim.api.nvim_set_hl(0, "AlloyTestVirtAdd", { fg = "#6A9A6A", bg = diff_add_bg_color, bold = true })
  vim.api.nvim_set_hl(0, "AlloyTestVirtDel", { fg = "#A06060", bg = diff_del_bg_color, bold = true })
  print_info(title)
  if state.diff_ns_id and state.output_buf then
    vim.api.nvim_buf_clear_namespace(state.output_buf, state.diff_ns_id, 0, -1)
  end
  local display_lines = { "", "```river", "" }
  for _, line_data in ipairs(lines_data) do
    table.insert(display_lines, "" .. line_data.content)
  end
  table.insert(display_lines, "")
  table.insert(display_lines, "```")
  table.insert(display_lines, "")
  local start_line = vim.api.nvim_buf_line_count(state.output_buf)
  log_message(display_lines)
  for i, line_data in ipairs(lines_data) do
    local line_to_highlight = start_line + 3 + (i - 1)
    local hl_group, virt_text_data
    if line_data.type == "added" then
      hl_group = "AlloyTestDiffAddBg"
      virt_text_data = { { "+", "AlloyTestVirtAdd" } }
    elseif line_data.type == "removed" then
      hl_group = "AlloyTestDiffDelBg"
      virt_text_data = { { "-", "AlloyTestVirtDel" } }
    end
    if hl_group and virt_text_data then
      vim.api.nvim_buf_set_extmark(
        state.output_buf,
        state.diff_ns_id,
        line_to_highlight,
        0,
        { line_hl_group = hl_group, virt_text = virt_text_data, virt_text_pos = "overlay", priority = 200 }
      )
    end
  end
end

local function read_file_from_tests_dir(filename)
  local file_path = vim.fn.getcwd() .. "/" .. config.override_dir_name .. "/" .. filename
  if vim.fn.filereadable(file_path) == 0 then
    print_error(string.format("Required test file not found or not readable: %s", file_path))
    return nil
  end
  local lines = vim.fn.readfile(file_path)
  local clean_lines = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(clean_lines, line)
    end
  end
  return clean_lines
end

function M.get_override_content(component_key)
  local override_file_path = vim.fn.getcwd()
    .. "/"
    .. config.override_dir_name
    .. "/"
    .. component_key
    .. "/localtest.alloy"
  if vim.fn.filereadable(override_file_path) == 1 then
    local content_lines = vim.fn.readfile(override_file_path)
    return table.concat(content_lines, "\n")
  end
  return nil
end

local function load_block_overrides()
  integration_state.notify_debug("Scanning for block overrides...")
  local overrides = {}
  local root_dir = vim.fn.getcwd()
  local override_path = root_dir .. "/" .. config.override_dir_name

  if vim.fn.isdirectory(override_path) == 0 then
    integration_state.notify_debug("No .alloy_tests directory found.")
    return overrides
  end

  integration_state.overridden_components = {}

  local items = vim.fn.readdir(override_path)
  local count = 0
  for _, item_name in ipairs(items) do
    local full_path = override_path .. "/" .. item_name
    local override_file_path = full_path .. "/localtest.alloy"

    if vim.fn.isdirectory(full_path) == 1 and vim.fn.filereadable(override_file_path) == 1 then
      local content_lines = vim.fn.readfile(override_file_path)
      if content_lines and #content_lines > 0 then
        local override_key = item_name
        local override_content = table.concat(content_lines, "\n")
        overrides[override_key] = override_content
        integration_state.overridden_components[override_key] = true
        count = count + 1
      end
    end
  end
  integration_state.notify_debug("Found " .. count .. " override(s).")
  return overrides
end

function M.update_override_state()
  integration_state.notify_debug("Updating override state...")
  local root_dir = vim.fn.getcwd()
  local override_path = root_dir .. "/" .. config.override_dir_name

  integration_state.overridden_components = {}

  if vim.fn.isdirectory(override_path) == 0 then
    return
  end

  local items = vim.fn.readdir(override_path)
  for _, item_name in ipairs(items) do
    local full_path = override_path .. "/" .. item_name
    local override_file_path = full_path .. "/localtest.alloy"
    if vim.fn.isdirectory(full_path) == 1 and vim.fn.filereadable(override_file_path) == 1 then
      integration_state.overridden_components[item_name] = true
    end
  end
end

local function show_summary_float(summary_data)
  if state.summary_win_id and vim.api.nvim_win_is_valid(state.summary_win_id) then
    return
  end
  vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal", default = true })
  local content, highlights = {}, {}
  local max_log_width = 60
  local all_logs = vim.list_extend(
    vim.list_extend(
      vim.list_extend(vim.list_extend({}, summary_data.logs_written), summary_data.logs_expected),
      summary_data.missing_logs
    ),
    summary_data.unexpected_logs
  )
  for _, log in ipairs(all_logs) do
    max_log_width = math.max(max_log_width, vim.fn.strwidth(log) + 10)
  end
  local editor_width = vim.api.nvim_get_option("columns")
  local max_allowed_width = math.floor(editor_width * 0.95)
  local window_width = math.min(max_log_width, max_allowed_width)
  local header_border = "╔" .. string.rep("═", window_width - 2) .. "╗"
  local footer_border = "╚" .. string.rep("═", window_width - 2) .. "╝"
  local divider = "╠" .. string.rep("═", window_width - 2) .. "╣"
  local function create_line(text, align)
    align = align or "left"
    local padding = window_width - 4
    local content_text = text or ""
    local text_width = vim.fn.strwidth(content_text)
    if align == "center" then
      local left_pad = math.floor((padding - text_width) / 2)
      local right_pad = padding - text_width - left_pad
      return "║ " .. string.rep(" ", left_pad) .. content_text .. string.rep(" ", right_pad) .. " ║"
    else
      local right_pad = padding - text_width
      return "║ " .. content_text .. string.rep(" ", math.max(0, right_pad)) .. " ║"
    end
  end
  table.insert(content, header_border)
  table.insert(content, create_line("🔍 ALLOY E2E TEST RESULTS", "center"))
  table.insert(highlights, { line = #content, hl_group = "Title" })
  table.insert(content, divider)
  table.insert(content, create_line(string.format("📖 Logs Expected: %d", #summary_data.logs_expected)))
  table.insert(highlights, { line = #content, hl_group = "Number" })
  table.insert(content, create_line(string.format("🔍 Logs Found:%d", #summary_data.logs_found)))
  table.insert(highlights, { line = #content, hl_group = "Number" })
  table.insert(content, create_line(string.format("❌ Missing:%d", #summary_data.missing_logs)))
  table.insert(highlights, { line = #content, hl_group = "DiagnosticError" })
  table.insert(content, create_line(string.format("❗ Unexpected:%d", #summary_data.unexpected_logs)))
  table.insert(highlights, { line = #content, hl_group = "WarningMsg" })
  table.insert(content, divider)
  local status_icon, status_text, status_hl
  if summary_data.test_passed then
    status_icon, status_text, status_hl = "✅", "TEST PASSED", "DiagnosticOk"
  else
    status_icon, status_text, status_hl = "❌", "TEST FAILED", "DiagnosticError"
  end
  table.insert(content, create_line(string.format("%s %s", status_icon, status_text), "center"))
  table.insert(highlights, { line = #content, hl_group = status_hl })
  table.insert(content, divider)
  table.insert(content, create_line("📝 INPUT LOGS (`logs_input.log`)", "left"))
  table.insert(highlights, { line = #content, hl_group = "Special" })
  for _, log in ipairs(summary_data.logs_written) do
    table.insert(content, create_line(log))
    table.insert(highlights, { line = #content, hl_group = "Comment" })
  end
  table.insert(content, divider)
  table.insert(content, create_line("📖 EXPECTED LOGS (`logs_expected.log`)", "left"))
  table.insert(highlights, { line = #content, hl_group = "Special" })
  for _, log in ipairs(summary_data.logs_expected) do
    table.insert(content, create_line(log))
    table.insert(highlights, { line = #content, hl_group = "Comment" })
  end
  table.insert(content, divider)
  table.insert(content, create_line("📊 DIFFERENCE ANALYSIS", "left"))
  table.insert(highlights, { line = #content, hl_group = "Special" })
  if summary_data.test_passed then
    table.insert(content, create_line(" All expected logs were found.", "left"))
    table.insert(highlights, { line = #content, hl_group = "DiagnosticOk" })
  else
    if #summary_data.missing_logs > 0 then
      table.insert(content, create_line(" ❌ Missing Logs (Expected but not found):", "left"))
      table.insert(highlights, { line = #content, hl_group = "DiagnosticError" })
      for _, log in ipairs(summary_data.missing_logs) do
        table.insert(content, create_line("- " .. log))
      end
    end
    if #summary_data.unexpected_logs > 0 then
      table.insert(content, create_line(" ❗ Unexpected Logs (Found but not expected):", "left"))
      table.insert(highlights, { line = #content, hl_group = "WarningMsg" })
      for _, log in ipairs(summary_data.unexpected_logs) do
        table.insert(content, create_line("+ " .. log))
      end
    end
  end
  table.insert(content, divider)
  table.insert(content, create_line("Press 'q' or <Esc> to close", "center"))
  table.insert(highlights, { line = #content, hl_group = "Comment" })
  table.insert(content, footer_border)
  local height = #content
  local editor_height = vim.api.nvim_get_option("lines")
  local row, col = math.floor((editor_height - height) / 2), math.floor((editor_width - window_width) / 2)
  local buf = vim.api.nvim_create_buf(false, true)
  local win_opts = {
    relative = "editor",
    style = "minimal",
    width = window_width,
    height = height,
    row = row,
    col = col,
    border = "none",
    zindex = 50,
  }
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  state.summary_win_id = win
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, -1, hl.hl_group, hl.line - 1, 0, -1)
  end
  for i = 0, #content - 1 do
    if i == 0 or i == #content - 1 then
      vim.api.nvim_buf_add_highlight(buf, -1, "FloatBorder", i, 0, -1)
    else
      local line_text = content[i + 1]
      local line_len_bytes = #line_text
      vim.api.nvim_buf_add_highlight(buf, -1, "FloatBorder", i, 0, 4)
      vim.api.nvim_buf_add_highlight(buf, -1, "FloatBorder", i, line_len_bytes - 4, line_len_bytes)
    end
  end
  vim.bo[buf].buftype, vim.bo[buf].swapfile, vim.bo[buf].bufhidden, vim.bo[buf].filetype =
    "nofile", false, "wipe", "alloy-summary"
  local close_win = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if state.summary_win_id == win then
      state.summary_win_id = nil
    end
  end
  vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
end

local function extract_log_contents(loki_result)
  local ok, parsed = pcall(vim.fn.json_decode, loki_result)
  if not ok or not parsed.data or not parsed.data.result then
    return {}
  end
  local found_logs = {}
  for _, result_entry in ipairs(parsed.data.result) do
    if result_entry.values then
      for _, value_pair in ipairs(result_entry.values) do
        table.insert(found_logs, value_pair[2])
      end
    end
  end
  return found_logs
end

function M.get_free_port()
  local server = vim.loop.new_tcp()
  if not server then
    return nil
  end
  if server:bind("0.0.0.0", 0) ~= 0 then
    server:close()
    return nil
  end
  local sock_info = server:getsockname()
  server:close()
  return sock_info and sock_info.port
end

-- --- Main Logic ---

function M.cleanup()
  integration_state.notify_debug("Cleanup started.")
  print_info("Cleaning up...")
  if state.alloy_pid then
    vim.loop.kill(state.alloy_pid, "SIGTERM")
    state.alloy_pid = nil
  end
  if config.manage_loki and state.loki_started_by_script then
    print_info("Stopping Loki container: " .. config.loki_container_name)
    vim.fn.jobstart({ "docker", "stop", config.loki_container_name })
    state.loki_started_by_script = false
  end
  if state.test_dir and vim.fn.isdirectory(state.test_dir) == 1 then
    print_info("Removing test directory: " .. state.test_dir)
    vim.fn.delete(state.test_dir, "rf")
  end
  if state.alloy_data_dir and vim.fn.isdirectory(state.alloy_data_dir) == 1 then
    print_info("Removing Alloy data directory: " .. state.alloy_data_dir)
    vim.fn.delete(state.alloy_data_dir, "rf")
    state.alloy_data_dir = nil
  end

  integration_state.overridden_components = {}
  integration_state.last_summary_data = nil

  print_info("Cleanup complete.")
  integration_state.notify_debug("Cleanup finished.")
end

function M.toggle_summary()
  if state.summary_win_id and vim.api.nvim_win_is_valid(state.summary_win_id) then
    vim.api.nvim_win_close(state.summary_win_id, true)
    state.summary_win_id = nil
  elseif state.last_summary_data then
    show_summary_float(state.last_summary_data)
  else
    print_info("No test summary available. Run the test first.")
  end
end

local function wait_for_service(name, url, callback)
  print_info(string.format("Waiting for %s to be ready at %s...", name, url))
  local timer = vim.loop.new_timer()
  local poll_count = 0
  local check_url = url
  if name == "Loki" then
    check_url = url .. "/loki/api/v1/status/buildinfo"
  elseif name == "Alloy" then
    check_url = url .. "/ready"
  end
  local poll = vim.schedule_wrap(function()
    poll_count = poll_count + 1
    if poll_count > 60 then
      timer:stop()
      print_error(string.format("Timeout waiting for %s.", name))
      M.cleanup()
      return
    end
    vim.fn.jobstart({ "curl", "--output", "/dev/null", "--silent", "--fail", check_url }, {
      on_exit = vim.schedule_wrap(function(_, code)
        if code == 0 then
          timer:stop()
          print_success(string.format("%s is ready.", name))
          integration_state.notify_debug(name .. " service is ready.")
          callback()
        end
      end),
    })
  end)
  timer:start(0, 500, poll)
end

local function start_or_recreate_loki_container(on_ready_callback)
  print_step("1. PREPARING LOKI CONTAINER")
  integration_state.notify_debug("Preparing Loki container.")
  if vim.fn.executable("docker") ~= 1 then
    print_error("`docker` command not found. Cannot start Loki.")
    M.cleanup()
    return
  end
  local function run_new_container()
    print_info("Starting new Loki container '" .. config.loki_container_name .. "'...")
    local docker_cmd = {
      "docker",
      "run",
      "-d",
      "--rm",
      "--name",
      config.loki_container_name,
      "-p",
      "3100:3100",
      config.loki_image,
      "-config.file=/etc/loki/local-config.yaml",
    }
    print_code(table.concat(docker_cmd, " "))
    vim.fn.jobstart(docker_cmd, {
      on_exit = vim.schedule_wrap(function()
        vim.loop.new_timer():start(
          2000,
          0,
          vim.schedule_wrap(function()
            state.loki_started_by_script = true
            wait_for_service("Loki", config.loki_url, on_ready_callback)
          end)
        )
      end),
    })
  end
  local function remove_container()
    print_info("Removing old Loki container (if it exists)...")
    vim.fn.jobstart({ "docker", "rm", "-v", config.loki_container_name }, {
      on_exit = vim.schedule_wrap(run_new_container),
    })
  end
  print_info("Stopping any previous Loki test container...")
  vim.fn.jobstart({ "docker", "stop", config.loki_container_name }, {
    on_exit = vim.schedule_wrap(remove_container),
  })
end

function M.run(opts)
  opts = opts or {}
  local source_bufnr = opts.source_bufnr or vim.api.nvim_get_current_buf()
  integration_state.notify_debug("Test run initiated for buffer: " .. source_bufnr)
  vim.notify("🚀 Starting Alloy E2E test...")

  if vim.bo[source_bufnr].filetype ~= "alloy" then
    print_error("Test runner must be initiated from an Alloy buffer or a diagram linked to one.")
    integration_state.notify_debug("Aborted: Test run initiated on non-alloy buffer.", vim.log.levels.WARN)
    return
  end

  state.source_win_id = vim.api.nvim_get_current_win()
  state.last_source_bufnr = source_bufnr

  state.test_dir = vim.fn.tempname()
  state.last_summary_data = nil
  if state.summary_win_id and vim.api.nvim_win_is_valid(state.summary_win_id) then
    vim.api.nvim_win_close(state.summary_win_id, true)
    state.summary_win_id = nil
  end

  setup_output_buffer()
  state.diff_ns_id = vim.api.nvim_create_namespace("alloy_test_diff")
  vim.api.nvim_create_autocmd("VimLeave", { pattern = "*", callback = M.cleanup, once = true })

  local function execute_query_and_verify()
    print_step("4. READING TEST CASE FILES")
    local logs_to_write = read_file_from_tests_dir("logs_input.log")
    if not logs_to_write then
      M.cleanup()
      return
    end
    local expected_logs = read_file_from_tests_dir("logs_expected.log")
    if not expected_logs then
      M.cleanup()
      return
    end
    if #logs_to_write == 0 then
      print_error("`logs_input.log` file is empty. Nothing to test.")
      M.cleanup()
      return
    end
    print_step("5. WRITING TEST LOGS")
    local log_file = state.test_dir .. "/app.log"
    local start_ns = string.format("%.0f", (vim.fn.localtime() - 1) * 1e9)
    vim.fn.writefile(logs_to_write, log_file, "a")
    print_info(string.format("%d log lines written to %s:", #logs_to_write, log_file))
    print_code(table.concat(logs_to_write, "\n"))
    print_info("Waiting 3 seconds for Alloy to process the file...")
    vim.loop.new_timer():start(
      3000,
      0,
      vim.schedule_wrap(function()
        print_step("6. QUERYING LOKI")
        integration_state.notify_debug("Querying Loki for results.")
        local query_url = string.format("%s/loki/api/v1/query_range", config.loki_url)
        local query = string.format('{filename="%s"}', log_file:gsub("\\", "/"))
        local end_ns = string.format("%.0f", (vim.fn.localtime() + 1) * 1e9)
        local curl_cmd = {
          "curl",
          "-G",
          "-s",
          query_url,
          "--data-urlencode",
          "query=" .. query,
          "--data-urlencode",
          "start=" .. start_ns,
          "--data-urlencode",
          "end=" .. end_ns,
        }
        print_info("Running query:")
        print_code(table.concat(curl_cmd, " "))
        vim.fn.jobstart(curl_cmd, {
          stdout_buffered = true,
          on_stdout = vim.schedule_wrap(function(_, data)
            if not data then
              print_error("No data received from Loki query.")
              M.cleanup()
              return
            end

            print_step("7. ANALYZING RESULTS")
            local loki_result = table.concat(data, "\n")
            local found_logs = extract_log_contents(loki_result)
            local found_set = {}
            for _, log in ipairs(found_logs) do
              found_set[log] = true
            end
            local expected_set = {}
            for _, log in ipairs(expected_logs) do
              expected_set[log] = true
            end
            local missing_logs = {}
            for _, log in ipairs(expected_logs) do
              if not found_set[log] then
                table.insert(missing_logs, log)
              end
            end
            local unexpected_logs = {}
            for _, log in ipairs(found_logs) do
              if not expected_set[log] then
                table.insert(unexpected_logs, log)
              end
            end
            local test_passed = (#missing_logs == 0 and #unexpected_logs == 0)

            local summary_data = {
              logs_written = logs_to_write,
              logs_expected = expected_logs,
              logs_found = found_logs,
              missing_logs = missing_logs,
              unexpected_logs = unexpected_logs,
              test_passed = test_passed,
            }
            state.last_summary_data = summary_data
            integration_state.last_summary_data = summary_data
            integration_state.notify_debug("Test finished. Passed: " .. tostring(test_passed))

            if test_passed then
              print_success("✅ TEST PASSED")
              vim.notify("✅ Alloy E2E Test Passed!")
            else
              print_error("❌ TEST FAILED")
              vim.notify("❌ Alloy E2E Test Failed!", vim.log.levels.ERROR)
            end

            integration_state.notify_debug("Notifying visualizer to update with results.")
            if
              integration_state.visualizer_module and integration_state.visualizer_module.update_diagram_with_results
            then
              integration_state.visualizer_module.update_diagram_with_results(summary_data)
            end

            show_summary_float(summary_data)
            M.cleanup()
          end),
        })
      end)
    )
  end

  local function start_alloy_and_test()
    print_step("2. SETTING UP ALLOY")
    integration_state.notify_debug("Setting up Alloy process.")
    state.alloy_port = M.get_free_port()
    if not state.alloy_port then
      print_error("Could not find a free port for Alloy.")
      M.cleanup()
      return
    end
    local alloy_config_file
    local log_file = state.test_dir .. "/app.log"
    vim.fn.writefile({}, log_file)
    if opts.rerun then
      alloy_config_file = state.test_dir .. "/config.alloy"
      print_info("Using previously generated config content.")
      vim.fn.writefile(state.last_alloy_config_content, alloy_config_file)

      --- FEATURE: Also show the config in the log for reruns.
      local lines_for_display = {}
      for _, line in ipairs(state.last_alloy_config_content) do
        table.insert(lines_for_display, { content = line, type = "unchanged" })
      end
      print_code_in_box("Using final Alloy configuration (rerun):", lines_for_display)
    else
      alloy_config_file = state.test_dir .. "/config.alloy"
      print_info("Scanning for block overrides in: " .. config.override_dir_name)
      local block_overrides = load_block_overrides()
      for key, _ in pairs(block_overrides) do
        print_info(string.format(" - Found block override for '%s'", key))
      end

      local original_lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
      local overrides_applied = {}
      local replacement_plan = {}
      local i = 1
      while i <= #original_lines do
        local line = original_lines[i]
        for key, new_content in pairs(block_overrides) do
          if not overrides_applied[key] then
            local type, label = key:match("^(.*)-([^-]+)$")
            if type and type ~= "" and label and label ~= "" then
              local start_pattern = "^%s*" .. vim.pesc(type) .. '%s*"' .. vim.pesc(label) .. '"'
              if line:match(start_pattern) then
                local block_start_idx = i
                local block_end_idx = -1
                local brace_level = 0
                local found_first_brace = false
                for j = block_start_idx, #original_lines do
                  local current_line = original_lines[j]
                  for char_idx = 1, #current_line do
                    local char = current_line:sub(char_idx, char_idx)
                    if char == "{" then
                      brace_level = brace_level + 1
                      found_first_brace = true
                    elseif char == "}" then
                      brace_level = brace_level - 1
                    end
                  end
                  if found_first_brace and brace_level == 0 then
                    block_end_idx = j
                    break
                  end
                end
                if block_end_idx ~= -1 then
                  print_info(string.format(' - Planning to replace block for `%s "%s"`.', type, label))
                  replacement_plan[block_start_idx] = {
                    start_idx = block_start_idx,
                    end_idx = block_end_idx,
                    content = new_content,
                  }
                  overrides_applied[key] = true
                  i = block_end_idx
                  break
                end
              end
            end
          end
        end
        i = i + 1
      end
      local final_lines_for_display = {}
      local final_lines_for_file = {}
      i = 1
      while i <= #original_lines do
        if replacement_plan[i] then
          local plan = replacement_plan[i]
          local block_diff_display = {}
          local original_block_lines = {}
          for k = plan.start_idx, plan.end_idx do
            table.insert(original_block_lines, original_lines[k])
          end
          local new_block_lines = vim.split(plan.content, "\n", { trimempty = false })
          local original_set = {}
          for _, line in ipairs(original_block_lines) do
            original_set[vim.trim(line)] = true
          end
          local new_set = {}
          for _, line in ipairs(new_block_lines) do
            new_set[vim.trim(line)] = true
          end
          local removed_lines_for_display = {}
          for _, line in ipairs(original_block_lines) do
            if not new_set[vim.trim(line)] then
              table.insert(removed_lines_for_display, { content = line, type = "removed" })
            end
          end
          local removed_lines_inserted = false
          for _, line in ipairs(new_block_lines) do
            table.insert(final_lines_for_file, line)
            if not original_set[vim.trim(line)] then
              table.insert(block_diff_display, { content = line, type = "added" })
              if not removed_lines_inserted then
                vim.list_extend(block_diff_display, removed_lines_for_display)
                removed_lines_inserted = true
              end
            else
              table.insert(block_diff_display, { content = line, type = "unchanged" })
            end
          end
          vim.list_extend(final_lines_for_display, block_diff_display)
          i = plan.end_idx + 1
        else
          table.insert(final_lines_for_display, { content = original_lines[i], type = "unchanged" })
          table.insert(final_lines_for_file, original_lines[i])
          i = i + 1
        end
      end
      for key, _ in pairs(block_overrides) do
        if not overrides_applied[key] then
          print_error(
            string.format(
              " - WARNING: Override for '%s' was found, but a matching block was not found in the source to replace.",
              key
            )
          )
        end
      end
      local placeholders = { LOG_FILE_PATH = log_file:gsub("\\", "/"), LOKI_URL = config.loki_url }
      for _, line_obj in ipairs(final_lines_for_display) do
        for p_key, p_value in pairs(placeholders) do
          line_obj.content = line_obj.content:gsub("{{" .. p_key .. "}}", p_value)
        end
      end
      for idx, line in ipairs(final_lines_for_file) do
        for p_key, p_value in pairs(placeholders) do
          final_lines_for_file[idx] = line:gsub("{{" .. p_key .. "}}", p_value)
        end
      end
      print_code_in_box("Using final Alloy configuration:", final_lines_for_display)
      vim.fn.writefile(final_lines_for_file, alloy_config_file)
      state.last_alloy_config_content = final_lines_for_file
    end
    print_info("Starting Alloy process...")
    local alloy_cmd = {
      "alloy",
      "run",
      "--server.http.listen-addr=0.0.0.0:" .. state.alloy_port,
      "--storage.path=" .. state.alloy_data_dir,
      alloy_config_file,
    }
    print_info("Running command: " .. table.concat(alloy_cmd, " "))
    state.alloy_pid = vim.fn.jobstart(alloy_cmd, {
      detached = true,
      stdout_buffered = true,
      on_stdout = vim.schedule_wrap(function(_, data)
        if data then
          for _, line in ipairs(data) do
            if line ~= "" then
              print_alloy_log(line)
            end
          end
        end
      end),
      stderr_buffered = true,
      on_stderr = vim.schedule_wrap(function(_, data)
        if data then
          print_error("Alloy process reported an error:")
          print_code(data)
        end
      end),
    })
    if not state.alloy_pid or state.alloy_pid <= 0 then
      print_error("Failed to start the Alloy process.")
      M.cleanup()
      return
    end
    print_step("3. VERIFYING ALLOY IS READY")
    wait_for_service("Alloy", "http://localhost:" .. state.alloy_port, execute_query_and_verify)
  end

  state.alloy_data_dir = vim.fn.tempname()
  vim.fn.mkdir(state.test_dir, "p")
  vim.fn.mkdir(state.alloy_data_dir, "p")
  if config.manage_loki then
    start_or_recreate_loki_container(start_alloy_and_test)
  else
    print_step("1. VERIFYING PRE-EXISTING LOKI")
    wait_for_service("Loki", config.loki_url, start_alloy_and_test)
  end
end

function M.rerun()
  if not state.last_alloy_config_content then
    print_error("No previous test configuration found to rerun.")
    return
  end
  if not state.last_source_bufnr or not vim.api.nvim_buf_is_valid(state.last_source_bufnr) then
    print_error("Cannot rerun test, the original source buffer was closed.")
    return
  end
  print_info("Rerunning the last test with the same configuration...")
  M.run({ rerun = true, source_bufnr = state.last_source_bufnr })
end

function M.setup()
  vim.keymap.set("n", "<leader>tar", function()
    M.run({ rerun = false })
  end, { desc = "Run Alloy E2E Test" })
  vim.keymap.set("n", "<leader>tas", M.toggle_summary, { desc = "Toggle Test Summary" })
  vim.keymap.set("n", "<leader>taR", M.rerun, { desc = "Rerun Last Alloy Test" })
  vim.keymap.set("n", "<leader>tal", M.toggle_test_log_window, { desc = "Toggle Alloy Test Log" })
end

return M
