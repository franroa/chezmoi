--[[
  GitLab CI Pipeline Visualizer for Neovim (v2)

  A more robust script to parse and display GitLab CI pipelines. This version
  includes a custom parser to better handle common GitLab features like `extends`.

  Features:
  - Interactive pipeline diagram organized by stages in a side panel.
  - Jump to the job definition in the source file without closing the diagram.
  - Displays which templates a job extends from.
  - View job details in a popup.
  - Smarter parsing of `extends` and `needs`.

  Limitations:
  - Does NOT resolve `include` directives from remote URLs or other files.
    The diagram is based ONLY on the content of the current buffer.
  - The YAML parser is basic and may fail on very complex syntax like
    YAML anchors or multi-line strings.
]]
local M = {}

-- ===================================================================
-- 1. Configuration & State
-- ===================================================================

-- Highlights for the diagram boxes.
local HLGroups = {
  key_order = { "Blue", "Green", "Cyan", "Purple", "Orange", "Red" },
  Orange = { fg = "#D19A66" },
  Blue = { fg = "#61AFEF" },
  Green = { fg = "#98C379" },
  Purple = { fg = "#C678DD" },
  Cyan = { fg = "#56B6C2" },
  Red = { fg = "#E06C75" },
  Follow = { bg = "#3E4452" },
  Dimmed = { fg = "#5c6370" },
}

-- Global state for the diagram window.
M.state = {
  is_open = false,
  win_id = nil,
  buf_id = nil,
  source_bufnr = nil,
  box_metadata = {},
  popup_win_id = nil,
}

local function setup_highlights()
  for name, hl in pairs(HLGroups) do
    if name ~= "key_order" then
      vim.api.nvim_set_hl(0, "GitlabDiagram" .. name, hl)
    end
  end
end

-- ===================================================================
-- 2. Custom CI Parser
-- This parser is more aware of YAML structure than the previous script.
-- ===================================================================

local Parser = {}

function Parser.get_indent(line)
  return line and line:match("^%s*"):len() or 0
end

-- Recursively parses a block of YAML-like lines.
function Parser.parse_block(lines, start_index, base_indent)
  if not start_index or start_index > #lines then
    return nil, start_index
  end
  base_indent = base_indent or Parser.get_indent(lines[start_index])
  if not lines[start_index] or vim.trim(lines[start_index]) == "" then
    return nil, start_index
  end

  local i = start_index
  local line = lines[i]

  -- Handle list
  if line:match("^%s*-") then
    local list = {}
    while i <= #lines do
      line = lines[i]
      if not line or Parser.get_indent(line) < base_indent then
        break
      end
      if Parser.get_indent(line) == base_indent and line:match("^%s*-") then
        local item_content = line:match("^%s*-%s*(.*)")
        -- Check for sub-block for this list item
        if lines[i + 1] and Parser.get_indent(lines[i + 1]) > base_indent then
          local sub_map, next_i = Parser.parse_block(lines, i + 1, Parser.get_indent(lines[i + 1]))
          if vim.trim(item_content) ~= "" then
            local k, v = item_content:match("([%w_.-]+):%s*(.*)")
            if k and sub_map then
              sub_map[k] = vim.trim(v)
            end
          end
          table.insert(list, sub_map)
          i = next_i
        else -- Simple one-line item
          table.insert(list, vim.trim(item_content))
          i = i + 1
        end
      else
        break
      end
    end
    return list, i
  end

  -- Handle map
  local map = {}
  while i <= #lines do
    line = lines[i]
    if not line or Parser.get_indent(line) < base_indent then
      break
    end
    if Parser.get_indent(line) > base_indent then -- Line is part of a value for previous key, which should have been handled.
      i = i + 1
      goto continue
    end

    local key, val = line:match("^%s*([%w_.-]+):%s*(.*)$")
    if key then
      val = vim.trim(val)
      if val == "" or val:match("^[|>]$") or (lines[i + 1] and Parser.get_indent(lines[i + 1]) > base_indent) then
        local sub_block, next_i = Parser.parse_block(lines, i + 1, Parser.get_indent(lines[i + 1]))
        map[key] = sub_block
        i = next_i
      else
        map[key] = val
        i = i + 1
      end
    else
      i = i + 1 -- Skip empty/comment/malformed lines
    end
    ::continue::
  end
  return map, i
end

-- Main parsing function.
function Parser.parse(buffer_content)
  local clean_lines = {}
  for _, line in ipairs(buffer_content) do
    -- Strip comments, but be careful not to strip URLs
    local clean_line = line
    if not clean_line:match("https://") then
      clean_line = clean_line:gsub("#.*", "")
    end
    if vim.trim(clean_line) ~= "" then
      table.insert(clean_lines, line)
    end
  end

  local top_level_map, _ = Parser.parse_block(clean_lines, 1, 0)

  if not top_level_map then
    return {}, {}
  end

  local jobs = {}
  local templates = {}
  local stages = top_level_map.stages or {}
  local job_line_map = {}

  -- Map lines to jobs for later navigation
  for i, line in ipairs(buffer_content) do
    if Parser.get_indent(line) == 0 then
      local key = line:match("^([%w_.-]+):")
      if key then
        job_line_map[key] = i
      end
    end
  end

  -- Separate templates from jobs
  for name, data in pairs(top_level_map) do
    if type(data) == "table" then
      if name:match("^%.") then
        templates[name] = data
      elseif
        name ~= "stages"
        and name ~= "variables"
        and name ~= "workflow"
        and name ~= "default"
        and name ~= "include"
      then
        jobs[name] = data
      end
    end
  end

  -- Second pass: process jobs, apply `extends`.
  local final_jobs = {}
  for name, data in pairs(jobs) do
    if type(data) == "table" then
      local final_data = vim.deepcopy(data)
      -- Handle `extends`
      if final_data.extends then
        local extensions = type(final_data.extends) == "string" and { final_data.extends } or final_data.extends
        if type(extensions) == "table" then
          for _, ext_name in ipairs(extensions) do
            if templates[ext_name] then
              for k, v in pairs(templates[ext_name]) do
                if final_data[k] == nil then
                  final_data[k] = v
                end
              end
            end
          end
        end
      end

      final_jobs[name] = {
        name = name,
        line = job_line_map[name],
        stage = final_data.stage or "test",
        needs = final_data.needs or nil,
        extends = final_data.extends or nil, -- MODIFIED: Store extends info
        content = vim.inspect(final_data),
        forward_to = {},
      }
    end
  end

  return final_jobs, stages
end

-- ===================================================================
-- 3. Graph Builder
-- Builds the dependency graph from the parsed data.
-- ===================================================================

local Graph = {}

function Graph.build(jobs, stages)
  local forward_targets = {}
  local jobs_by_stage = {}

  if type(stages) ~= "table" then
    vim.notify("Could not parse 'stages' block.", vim.log.levels.WARN)
    stages = {}
  end

  -- Populate stages
  for _, stage_name in ipairs(stages) do
    jobs_by_stage[stage_name] = {}
  end
  for name, job in pairs(jobs) do
    if type(job.stage) == "string" and jobs_by_stage[job.stage] then
      table.insert(jobs_by_stage[job.stage], name)
    end
  end

  -- Build dependencies
  for name, job in pairs(jobs) do
    if job.needs and type(job.needs) == "table" then
      -- Priority 1: `needs` dependencies
      for _, need_entry in ipairs(job.needs) do
        local needed_job_name = nil
        if type(need_entry) == "string" then
          needed_job_name = need_entry
        elseif type(need_entry) == "table" and need_entry.job then
          needed_job_name = need_entry.job
        end

        if needed_job_name and jobs[needed_job_name] then
          table.insert(jobs[needed_job_name].forward_to, name)
          forward_targets[name] = true
        end
      end
    else
      -- Priority 2: `stage` dependencies
      local job_stage = job.stage
      if type(job_stage) == "string" then
        local stage_idx = vim.fn.match(stages, job_stage) + 1
        if stage_idx > 1 then
          local prev_stage = stages[stage_idx - 1]
          if jobs_by_stage[prev_stage] then
            for _, prev_job_name in ipairs(jobs_by_stage[prev_stage]) do
              table.insert(jobs[prev_job_name].forward_to, name)
              forward_targets[name] = true
            end
          end
        end
      else
        vim.notify("Skipping stage dependency for job '" .. job.name .. "': malformed stage data.", vim.log.levels.WARN)
      end
    end
  end

  -- Find start nodes
  local start_nodes = {}
  for name, _ in pairs(jobs) do
    if not forward_targets[name] then
      table.insert(start_nodes, name)
    end
  end

  -- Trace all paths from start nodes
  local all_chains = {}
  for _, start_key in ipairs(start_nodes) do
    local stack = { { start_key } }
    while #stack > 0 do
      local current_path = table.remove(stack)
      local last_key = current_path[#current_path]
      local node = jobs[last_key]
      if node and #node.forward_to > 0 then
        for _, next_key in ipairs(node.forward_to) do
          if not vim.tbl_contains(current_path, next_key) then
            local new_path = vim.deepcopy(current_path)
            table.insert(new_path, next_key)
            table.insert(stack, new_path)
          end
        end
      else
        table.insert(all_chains, current_path)
      end
    end
  end

  -- Assign colors
  local color_keys = HLGroups.key_order
  for i, chain in ipairs(all_chains) do
    local color = color_keys[(i - 1) % #color_keys + 1]
    for _, job_name in ipairs(chain) do
      if jobs[job_name] and not jobs[job_name].color then
        jobs[job_name].color = color
      end
    end
  end

  return jobs, all_chains
end

-- ===================================================================
-- 4. Diagram Renderer
-- Draws the graph in a side window, organized by stage.
-- ===================================================================

local Diagram = {}

function Diagram.draw(stages, jobs, source_bufnr)
  if #stages == 0 then
    print("No pipeline stages found to visualize.")
    return
  end

  local final_content, box_metadata = {}, {}
  local color_keys = HLGroups.key_order

  -- Group jobs by their stage name for easy access.
  local jobs_by_stage = {}
  for _, stage_name in ipairs(stages) do
    jobs_by_stage[stage_name] = {}
  end
  for name, job in pairs(jobs) do
    if jobs_by_stage[job.stage] then
      table.insert(jobs_by_stage[job.stage], job)
    end
  end

  -- Build the content lines stage by stage.
  for i, stage_name in ipairs(stages) do
    local stage_jobs = jobs_by_stage[stage_name]
    if stage_jobs and #stage_jobs > 0 then
      if #final_content > 0 then
        table.insert(final_content, "") -- Add a spacer line
      end

      -- Add a styled stage header
      local header_text = "─── Stage: " .. stage_name .. " "
      table.insert(final_content, header_text)

      -- Sort jobs alphabetically within the stage
      table.sort(stage_jobs, function(a, b)
        return a.name < b.name
      end)

      for _, job in ipairs(stage_jobs) do
        local current_line_num = #final_content + 1
        local job_label = "  📦 " .. job.name
        local line_text = job_label
        local details = {}

        -- MODIFIED: Add 'extends' info to the details
        if job.extends then
          local extensions = type(job.extends) == "string" and { job.extends } or job.extends
          if type(extensions) == "table" and #extensions > 0 then
            table.insert(details, "extends: " .. table.concat(extensions, ", "))
          end
        end

        -- Add 'needs' info to the details
        if job.needs and type(job.needs) == "table" and #job.needs > 0 then
          local needs_list = {}
          for _, need_entry in ipairs(job.needs) do
            local needed_job = type(need_entry) == "string" and need_entry or (need_entry.job or nil)
            if needed_job then
              table.insert(needs_list, needed_job)
            end
          end
          if #needs_list > 0 then
            table.insert(details, "needs: " .. table.concat(needs_list, ", "))
          end
        end

        -- Append details to the line text
        if #details > 0 then
          line_text = line_text .. "  (" .. table.concat(details, "; ") .. ")"
        end

        table.insert(final_content, line_text)

        -- Store metadata for the clickable job name
        table.insert(box_metadata, {
          name = job.name,
          line_in_diagram = current_line_num,
          start_col = string.len("  "), -- Start highlight after indentation
          end_col = string.len(job_label),
          source_line = job.line,
          content = job.content,
        })
      end
    end
  end

  if #final_content == 0 then
    vim.notify("No jobs found for the defined stages.", vim.log.levels.WARN)
    return
  end

  -- Calculate a suitable width for the sidebar
  local width = 0
  for _, line in ipairs(final_content) do
    width = math.max(width, vim.fn.strwidth(line))
  end
  width = math.min(width + 4, 100) -- Set a max width

  -- Create a new buffer and fill it with the diagram content
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, final_content)

  -- Open a new vertical split on the right. Focus moves to the new window.
  vim.cmd("rightbelow vsplit")

  -- Configure the new window
  local win_id = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win_id, buf)
  vim.api.nvim_win_set_width(win_id, width)

  -- Set window options
  vim.wo[win_id].cursorline = true
  vim.wo[win_id].number = false
  vim.wo[win_id].relativenumber = false
  vim.wo[win_id].signcolumn = "no"
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "gitlab_ci_diagram"

  -- Defer highlights to ensure the buffer and window are fully ready.
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    -- Apply stage header highlights
    local current_line = 1
    for i, stage_name in ipairs(stages) do
      local stage_jobs = jobs_by_stage[stage_name]
      if stage_jobs and #stage_jobs > 0 then
        if current_line > 1 then
          current_line = current_line + 1
        end
        local stage_color = "GitlabDiagram" .. color_keys[(i - 1) % #color_keys + 1]
        local header_text = "─── Stage: " .. stage_name .. " "
        vim.api.nvim_buf_add_highlight(buf, -1, stage_color, current_line - 1, 0, string.len(header_text))
        vim.api.nvim_buf_add_highlight(buf, -1, "GitlabDiagramDimmed", current_line - 1, string.len(header_text), -1)
        current_line = current_line + #stage_jobs + 1
      end
    end

    -- Apply job name highlights
    for _, box in ipairs(box_metadata) do
      vim.api.nvim_buf_add_highlight(buf, -1, "GitlabDiagramCyan", box.line_in_diagram - 1, box.start_col, box.end_col)
    end
  end, 20)

  -- Update global state
  M.state = {
    is_open = true,
    win_id = win_id,
    buf_id = buf,
    source_bufnr = source_bufnr,
    box_metadata = box_metadata,
  }

  -- Cleanup on close
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win_id),
    once = true,
    callback = function()
      if M.state.win_id == win_id then
        M.state.is_open = false
      end
    end,
  })

  return M.state
end

-- ===================================================================
-- 5. User-Facing Functions & Keymaps
-- ===================================================================

function M.get_box_at_cursor()
  if not M.state.is_open then
    return nil
  end
  local pos = vim.api.nvim_win_get_cursor(M.state.win_id)
  local r, c = pos[1], pos[2] + 1
  for _, box in ipairs(M.state.box_metadata) do
    if r == box.line_in_diagram and c >= box.start_col and c <= box.end_col then
      return box
    end
  end
  return nil
end

function M.show_job_popup(box)
  if not box then
    return
  end
  M.close_job_popup()
  local content = vim.split(box.content, "\n")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].filetype = "yaml"

  local width = 0
  for _, line in ipairs(content) do
    width = math.max(width, vim.fn.strwidth(line))
  end

  M.state.popup_win_id = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    width = math.min(width + 4, 80),
    height = math.min(#content, 20),
    style = "minimal",
    border = "rounded",
    title = "Job: " .. box.name,
    zindex = 100,
  })
end

function M.close_job_popup()
  if M.state.popup_win_id and vim.api.nvim_win_is_valid(M.state.popup_win_id) then
    vim.api.nvim_win_close(M.state.popup_win_id, true)
    M.state.popup_win_id = nil
  end
end

function M.setup_diagram_keymaps()
  local buf = M.state.buf_id
  -- Go to definition
  vim.keymap.set("n", "<CR>", function()
    local box = M.get_box_at_cursor()
    if box and box.source_line then
      -- MODIFIED: Jump without closing the diagram window
      local source_win_id = vim.fn.bufwinid(M.state.source_bufnr)
      if source_win_id > 0 then
        -- Switch focus to the source window
        vim.api.nvim_set_current_win(source_win_id)
        -- Set the cursor position in that window
        vim.api.nvim_win_set_cursor(source_win_id, { box.source_line, 0 })
      else
        vim.notify("Source buffer window not found.", vim.log.levels.WARN)
      end
    end
  end, { buffer = buf, silent = true, desc = "Go to Job Definition" })
  -- Close
  vim.keymap.set("n", "q", function()
    -- This now closes only the diagram window, as expected.
    vim.api.nvim_win_close(M.state.win_id, true)
  end, { buffer = buf, silent = true, desc = "Close Diagram" })
  -- Show popup
  vim.keymap.set("n", "K", function()
    M.show_job_popup(M.get_box_at_cursor())
  end, { buffer = buf, silent = true, desc = "Show Job Details" })
end

--- Toggles the main pipeline diagram.
function M.TogglePipelineDiagram()
  if M.state.is_open then
    -- If the window is already open, just close it.
    if M.state.win_id and vim.api.nvim_win_is_valid(M.state.win_id) then
      vim.api.nvim_win_close(M.state.win_id, true)
    end
    M.state.is_open = false
    return
  end

  local source_bufnr = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)

  vim.notify("Parsing GitLab CI file...", vim.log.levels.INFO)
  local jobs, stages = Parser.parse(content)
  if vim.tbl_isempty(jobs) then
    vim.notify("No jobs found in the file.", vim.log.levels.WARN)
    return
  end

  vim.notify("Building dependency graph...", vim.log.levels.INFO)
  -- The `Graph.build` function is still useful for processing `extends` and `needs`.
  local processed_jobs, _ = Graph.build(jobs, stages)

  vim.notify("Drawing diagram...", vim.log.levels.INFO)
  -- Call the draw function with stages and jobs.
  Diagram.draw(stages, processed_jobs, source_bufnr)
  if M.state.is_open then
    M.setup_diagram_keymaps()
  end
end

--- Sets up the commands and autocommands for the plugin.
function M.setup()
  setup_highlights()
  vim.api.nvim_create_user_command("GitlabPipeline", M.TogglePipelineDiagram, {
    desc = "Toggle GitLab CI pipeline diagram",
  })

  -- You can also create a keymap for this.
  -- vim.keymap.set("n", "<leader>cp", M.TogglePipelineDiagram, { desc = "CI: Toggle Pipeline Diagram" })
end

function M.run_job_at_cursor()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  
  local excluded_keys = {
    "stages",
    "variables",
    "workflow",
    "default",
    "include",
  }
  
  local job_name = nil
  
  for i = cursor_line, 1, -1 do
    local line = lines[i]
    if line and vim.trim(line) ~= "" then
      local indent = line:match("^%s*"):len()
      
      if indent == 0 then
        local key = line:match("^([%w_.-]+):")
        if key then
          if not key:match("^%.") and not vim.tbl_contains(excluded_keys, key) then
            job_name = key
            break
          end
        end
        break
      end
    end
  end

  if not job_name then
    vim.notify("Not inside a GitLab CI job (cursor at line " .. cursor_line .. ")", vim.log.levels.WARN)
    return
  end

  vim.notify("Found job: " .. job_name, vim.log.levels.INFO)

  local source_bufnr = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
  local jobs, stages = Parser.parse(content)

  if not jobs[job_name] then
    vim.notify("Job '" .. job_name .. "' not found in parsed config", vim.log.levels.WARN)
    return
  end

  vim.notify("Running job: " .. job_name, vim.log.levels.INFO)

  require("overseer").run_template({
    name = "GitLab CI Job",
    params = {
      job = job_name,
    },
  }, function(task)
    if task then
      require("overseer").run_action(task, "open float")
    end
  end)
end

M.setup()

return M
