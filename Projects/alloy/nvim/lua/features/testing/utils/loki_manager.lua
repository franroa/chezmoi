local M = {}

local config = {
  loki_url = "http://localhost:3100",
  manage_loki = true,
  loki_container_name = "neovim-loki-test",
  loki_image = "grafana/loki:3.0.0",
}

local state = {
  loki_started_by_script = false,
}

local function wait_for_service(name, url, callback, logger)
  logger.info(string.format("Waiting for %s to be ready at %s...", name, url))
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
      logger.error(string.format("Timeout waiting for %s.", name))
      return
    end
    vim.fn.jobstart({ "curl", "--output", "/dev/null", "--silent", "--fail", check_url }, {
      on_exit = vim.schedule_wrap(function(_, code)
        if code == 0 then
          timer:stop()
          logger.success(string.format("%s is ready.", name))
          callback()
        end
      end),
    })
  end)
  timer:start(0, 500, poll)
end

local function start_or_recreate_loki_container(on_ready_callback, logger)
  logger.step("1. PREPARING LOKI CONTAINER")
  if vim.fn.executable("docker") ~= 1 then
    logger.error("`docker` command not found. Cannot start Loki.")
    return false
  end

  local function run_new_container()
    logger.info("Starting new Loki container '" .. config.loki_container_name .. "'...")
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
    logger.code(table.concat(docker_cmd, " "))
    vim.fn.jobstart(docker_cmd, {
      on_exit = vim.schedule_wrap(function()
        vim.loop.new_timer():start(
          2000,
          0,
          vim.schedule_wrap(function()
            state.loki_started_by_script = true
            wait_for_service("Loki", config.loki_url, on_ready_callback, logger)
          end)
        )
      end),
    })
  end

  local function remove_container()
    logger.info("Removing old Loki container (if it exists)...")
    vim.fn.jobstart({ "docker", "rm", "-v", config.loki_container_name }, {
      on_exit = vim.schedule_wrap(run_new_container),
    })
  end

  logger.info("Stopping any previous Loki test container...")
  vim.fn.jobstart({ "docker", "stop", config.loki_container_name }, {
    on_exit = vim.schedule_wrap(remove_container),
  })

  return true
end

function M.start_loki(on_ready_callback, logger)
  if config.manage_loki then
    return start_or_recreate_loki_container(on_ready_callback, logger)
  else
    logger.step("1. VERIFYING PRE-EXISTING LOKI")
    wait_for_service("Loki", config.loki_url, on_ready_callback, logger)
    return true
  end
end

function M.stop_loki(logger)
  if config.manage_loki and state.loki_started_by_script then
    logger.info("Stopping Loki container: " .. config.loki_container_name)
    vim.fn.jobstart({ "docker", "stop", config.loki_container_name })
    state.loki_started_by_script = false
  end
end

function M.wait_for_service(name, url, callback, logger)
  wait_for_service(name, url, callback, logger)
end

function M.get_loki_url()
  return config.loki_url
end

function M.set_config(new_config)
  config = vim.tbl_extend("force", config, new_config)
end

return M
