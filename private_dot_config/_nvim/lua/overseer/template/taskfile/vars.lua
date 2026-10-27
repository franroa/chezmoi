local tmpl = {
  name = "Taskfile Vars",
  params = {
    module = { type = "string", default = vim.env.MODULE_ENV_VAR },
    region = { type = "string", default = vim.env.REGION_ENV_VAR },
    tier = { type = "string", default = vim.env.TIER_ENV_VAR },
  },
  builder = function(params)
    return {
      cmd = "task " .. task_name,
    }
  end,
}
return tmpl
