local fn = vim.fn
local api = vim.api

local M = {}
function M.lazy_plugins()
  Snacks.picker.files({
    dirs = { vim.fn.stdpath("data") .. "/lazy" },
    cmd = "fd",
    args = { "-td", "--exact-depth", "1" },
    confirm = function(picker, item, action)
      picker:close()
      if item and item.file then
        vim.schedule(function()
          local where = action and action.name or "confirm"
          if where == "edit_vsplit" then
            vim.cmd("vsplit | lcd " .. item.file)
          elseif where == "edit_split" then
            vim.cmd("split | lcd " .. item.file)
          else
            vim.cmd("tabnew | tcd " .. item.file)
          end
        end)
      end

      vim.cmd("ex " .. item.file)
    end,
  })
end

function M.find_directory()
  local find_directory = function(opts, ctx)
    return require("snacks.picker.source.proc").proc({
      opts,
      {
        cmd = "fd",
        args = {
          "--type",
          "d",
          "--hidden",
          "--exclude",
          ".git",
          "--exclude",
          ".npm",
          "--exclude",
          "node_modules",
        },
      },
    }, ctx)
  end

  local change_directory = function(picker)
    picker:close()
    local item = picker:current()
    if not item then
      return
    end
    local dir = item.text
    vim.fn.chdir(dir)
  end

  Snacks.picker.pick({
    source = "Directories",
    finder = find_directory,
    format = "text",
    confirm = change_directory,
    preview = "none",
    layout = {
      preset = "select",
    },
  })
end

function M.find_cmake_targets()
  local find_cmake_targets = function(opts, ctx)
    return require("snacks.picker.source.proc").proc({
      opts,
      {
        cwd = LazyVim.root.git(),
        cmd = "task",
        args = {
          "--list-all",
        },
        transform = function(item)
          if item.text:sub(1, 1) ~= "*" then
            return false
          else
            item.text = vim.split(string.sub(item.text, 2), ":")[1]
          end
        end,
      },
    }, ctx)
  end

  Snacks.picker.pick({
    source = "Taskfile Targets",
    finder = find_cmake_targets,
    preview = "none",
    format = "text",
    layout = {
      preset = "select",
    },
    confirm = function(picker, item)
      require("overseer").run_template({
        name = "Taskfile Task",
        params = {
          region = vim.env.REGION_ENV_VAR,
          tier = vim.env.TIER_ENV_VAR,
          domain = vim.env.DOMAIN_ENV_VAR,
          action = item.text,
          --   target = vim.env.TARGET_ENV_VAR,
        },
      }, function(task)
        if task then
          require("overseer").run_action(task, "open float")
        end
      end)
      picker:close()
    end,
  })
end

function M.venv_selector()
  local gui_utils = require("venv-selector.gui.utils")

  local M = {}
  M.__index = M

  function M.new()
    local self = setmetatable({ results = {}, picker = nil }, M)
    return self
  end

  function M:pick()
    return Snacks.picker.pick({
      title = "Python Venv",
      finder = function(opts, ctx)
        return self.results
      end,
      layout = {
        preset = "select",
      },
      format = function(item, picker)
        return {
          { item.icon, gui_utils.hl_active_venv(item) },
          { " " },
          { string.format("%8s", item.source) },
          { "  " },
          { item.name },
        }
      end,
      confirm = function(picker, item)
        if item then
          gui_utils.select(item)
        end
        picker:close()
      end,
    })
  end

  function M:insert_result(result)
    result.text = result.source .. " " .. result.name
    table.insert(self.results, result)
    if self.picker then
      self.picker:find()
    else
      self.picker = self:pick()
    end
  end

  function M:search_done()
    self.results = gui_utils.remove_dups(self.results)
    gui_utils.sort_results(self.results)
    self.picker:find()
  end

  require("venv-selector.search").run_search(M.new(), nil)
end

---Finds the `inventory.yaml` file by searching up from the current directory.
---@return string? path The path to the inventory file, or nil if not found.
local function find_inventory_file()
  -- Get the directory of the current file
  local current_file_path = api.nvim_buf_get_name(0)
  if current_file_path == "" then
    -- If the buffer is unnamed, use the current working directory
    return fn.findfile("inventory.yaml", ".;")
  end

  -- Use findfile with the path of the current buffer
  local inventory_path = fn.findfile("inventory.yaml", fn.fnamemodify(current_file_path, ":h") .. ";")
  if inventory_path and inventory_path ~= "" then
    return inventory_path
  end
  return nil
end

---Parses the inventory YAML file and extracts all hostnames.
---@param file_path string The path to the inventory.yaml file.
---@return table hosts A list of server hostnames.
local function get_hosts_from_inventory(file_path)
  -- Use `yq` to parse all host keys from the YAML file.
  -- The expression '.. | .hosts? | keys | .[]' recursively finds all 'hosts' maps,
  -- gets their keys, and outputs each key on a new line.
  local command = "yq ' .all.hosts? | keys | .[]' " .. fn.shellescape(file_path)
  local output = fn.system(command)

  if vim.v.shell_error ~= 0 then
    vim.notify("Error parsing inventory.yaml. Is 'yq' installed and in your PATH?", vim.log.levels.ERROR)
    return {}
  end

  if output == "" then
    return {}
  end

  -- Split the output string into a table of lines (hosts)
  local hosts = vim.split(output, "\n", { trimempty = true })

  -- Remove duplicates and sort
  local seen = {}
  local unique_hosts = {}
  for _, host in ipairs(hosts) do
    if not seen[host] then
      table.insert(unique_hosts, host)
      seen[host] = true
    end
  end
  table.sort(unique_hosts)

  return unique_hosts
end

---Checks if the current buffer filename matches any of the known playbooks.
---@return string|nil playbook The filename of the matching playbook, or nil if not found.
local function get_current_buffer_playbook()
  local current_file = api.nvim_buf_get_name(0)
  if current_file == "" then
    return nil
  end

  local filename = fn.fnamemodify(current_file, ":t")
  local known_playbooks = {
    "linux_config_alloy_apps.yaml",
    "linux_config_alloy_nginx.yaml",
    "system_updates.yaml",
    "security_hardening.yaml",
    "windows_server_configuration.yaml",
    "docker_setup.yaml",
    "monitoring_setup.yaml",
  }

  for _, playbook in ipairs(known_playbooks) do
    if filename == playbook then
      return playbook
    end
  end

  return nil
end

---Main function to find inventory and show the server picker using Snacks.
function M.pick_server(host)
  local inventory_file = find_inventory_file()
  if not inventory_file then
    vim.notify("inventory.yaml not found in project.", vim.log.levels.WARN)
    return
  end

  local hosts = get_hosts_from_inventory(inventory_file)
  if #hosts == 0 then
    vim.notify("No hosts found in " .. inventory_file, vim.log.levels.INFO)
    return
  end

  -- Configure and launch the Snacks picker
  Snacks.picker.pick({
    -- The source is the list of host strings we just generated.
    source = "Ansible Hosts",
    -- We use a function that returns the hosts as properly formatted items.
    finder = function(opts, ctx)
      local items = {}
      for _, host in ipairs(hosts) do
        table.insert(items, { text = host })
      end
      return items
    end,
    -- Each item in the list is just plain text.
    format = "text",

    confirm = function(picker, item)
      picker:close()
      local current_playbook = get_current_buffer_playbook()
      if current_playbook then
        -- Current buffer is a known playbook, use it directly
        require("overseer").run_template({
          name = "Ansible Playbook",
          params = {
            server = item.text,
            playbook = current_playbook,
          },
        }, function(task)
          if task then
            require("overseer").run_action(task, "open float")
          end
        end)
      else
        -- Current buffer is not a known playbook, show picker
        M.pick_playbook(item.text)
      end
    end,
    -- No preview is needed for this simple list.
    preview = "none",
    -- Use a standard layout preset.
    layout = {
      preset = "select",
      width = 60, -- You can customize the width
    },
  })
end
function M.pick_playbook_with_current_host()
  M.pick_playbook(require("functions.treesitter_ansible").find_and_pick_ansible_host())
end

---Parses the SSH config file and extracts hostnames with "tunnel" suffix.
---@return table hosts A list of SSH hostnames with "tunnel" suffix.
local function get_ssh_hosts()
  local ssh_config_path = fn.expand("~/.ssh/config")

  if fn.filereadable(ssh_config_path) == 0 then
    vim.notify("SSH config file not found at " .. ssh_config_path, vim.log.levels.WARN)
    return {}
  end

  local hosts = {}
  local lines = fn.readfile(ssh_config_path)

  for _, line in ipairs(lines) do
    -- Match lines starting with "Host " and extract the hostname
    local host = line:match("^%s*Host%s+(.+)")
    if host then
      -- Only include hosts with tunnel suffix, skip wildcards
      if not host:match("[*?]") and host:match("tunnel$") then
        table.insert(hosts, (host:gsub("%s+", "")))
      end
    end
  end

  -- Remove duplicates and sort
  local seen = {}
  local unique_hosts = {}
  for _, host in ipairs(hosts) do
    if not seen[host] then
      table.insert(unique_hosts, host)
      seen[host] = true
    end
  end
  table.sort(unique_hosts)

  return unique_hosts
end

---SSH host picker using Snacks.
function M.pick_ssh_host()
  local hosts = get_ssh_hosts()

  if #hosts == 0 then
    vim.notify("No SSH hosts with 'tunnel' suffix found in ~/.ssh/config", vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    source = "SSH Hosts",
    finder = function(opts, ctx)
      local items = {}
      for _, host in ipairs(hosts) do
        table.insert(items, { text = host })
      end
      return items
    end,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item then
        require("overseer").run_template({
          name = "SSH Tunnel",
          params = {
            host = item.text,
          },
        }, function(task)
          -- if task then
          --   require("overseer").run_action(task, "open float")
          --   vim.cmd("OverseerClose")
          -- end
        end)
      end
    end,
    preview = "none",
    layout = {
      preset = "select",
      width = 60,
    },
  })
end
function M.pick_playbook(selected_host)
  local playbook_choices = {
    { name = "Linux Install Alloy", value = "linux_install_alloy.yaml" },
    { name = "Linux Config Alloy Apps", value = "linux_config_alloy_apps.yaml" },
    { name = "Linux Config Alloy NGINX", value = "linux_config_alloy_nginx.yaml" },
    { name = "System Updates", value = "system_updates.yaml" },
    { name = "Security Hardening", value = "security_hardening.yaml" },
    { name = "Window Server Configuratoin", value = "windows_server_configuration.yaml" },
    { name = "Docker Setup", value = "docker_setup.yaml" },
    { name = "Monitoring Setup", value = "monitoring_setup.yaml" },
  }

  Snacks.picker.pick({
    source = selected_host,
    finder = function(opts, ctx)
      local items = {}

      -- Add current buffer option if it's a YAML file (even if not in static list)
      local current_file = api.nvim_buf_get_name(0)
      if current_file ~= "" then
        local filename = fn.fnamemodify(current_file, ":t")
        if filename:match("%.ya?ml$") then
          table.insert(items, {
            text = "Use Current Buffer: " .. filename,
            value = filename,
            is_current_buffer = true,
          })
        end
      end

      -- Add static playbook choices
      for _, playbook in ipairs(playbook_choices) do
        table.insert(items, { text = playbook.name, value = playbook.value })
      end
      return items
    end,
    format = "text",
    confirm = function(picker, item)
      require("overseer").run_template({
        name = "Ansible Playbook",
        params = {
          server = selected_host,
          playbook = item.value,
        },
      }, function(task)
        if task then
          require("overseer").run_action(task, "open float")
        end
      end)
      picker:close()
    end,
    preview = "none",
    layout = {
      preset = "select",
      width = 60,
    },
  })
end

function M.gitlab_ci_jobs()
  local current_bufnr = api.nvim_get_current_buf()
  local content = api.nvim_buf_get_lines(current_bufnr, 0, -1, false)
  
  local gitlab_module = require("functions.gitlab")
  local jobs, stages = gitlab_module.Parser.parse(content)

  if vim.tbl_isempty(jobs) then
    vim.notify("No GitLab CI jobs found in current file", vim.log.levels.WARN)
    return
  end

  local items = {}
  for job_name, job_data in pairs(jobs) do
    table.insert(items, {
      text = job_name,
      stage = job_data.stage,
      job_name = job_name,
    })
  end

  table.sort(items, function(a, b)
    return a.text < b.text
  end)

  Snacks.picker.pick({
    source = "GitLab CI Jobs",
    finder = function(opts, ctx)
      return items
    end,
    format = function(item, picker)
      return {
        { item.text },
        { "  [" .. item.stage .. "]", "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      require("overseer").run_template({
        name = "GitLab CI Job",
        params = {
          job = item.job_name,
        },
      }, function(task)
        if task then
          require("overseer").run_action(task, "open float")
        end
      end)
    end,
    preview = "none",
    layout = {
      preset = "select",
    },
  })
end

return M
