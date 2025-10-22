local tmpl = {
  name = "Taskfile Task",
  params = {
    region = {
      type = "enum",
      choices = { "eu01", "us01", "ca01" },
      desc = " -- eu01, ca01, us01",
      order = 2, -- determines order of parameters in the UI
      optional = false,
      default = vim.env.REGION_ENV_VAR,
    },
    module = { order = 1, type = "string", default = vim.env.MODULE_ENV_VAR },
    tier = {
      type = "enum",
      desc = " -- live, sandbox",
      choices = { "live", "sandbox" },
      order = 3, -- determines order of parameters in the UI
      optional = false,
      default = vim.env.TIER_ENV_VAR,
    },
    domain = {
      type = "enum",
      desc = " -- platform, technosylva",
      choices = { "platform", "technosylva" },
      order = 4,
      optional = false,
      default = vim.env.DOMAIN_ENV_VAR,
    },
    target = { type = "string", optional = true },
    action = {
      type = "string",
      order = 5, -- determines order of parameters in the UI
      optional = false,
    },
  },
  builder = function(params)
    vim.env.TSYL_REGION = params.region
    vim.env.TSYL_TIER = params.tier
    vim.env.TSYL_DOMAIN = params.domain
    vim.env.TSYL_MODULE = params.module
    -- Base command string
    local cmd_str = "TF_LOG=error "
      .. " MODULE="
      .. params.module
      .. " REGION="
      .. params.region
      .. " TIER="
      .. params.tier
      .. " DOMAIN="
      .. params.domain
      .. " task "
      .. params.action

    if params.target and params.target ~= "" then
      cmd_str = cmd_str .. " TARGET=" .. params.target
    end

    return {
      cmd = cmd_str,
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
