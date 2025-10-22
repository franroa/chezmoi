-- https://www.youtube.com/watch?v=rerTvidyz-0
local tmpl = {
  name = "Terraform Apply Target",
  strategy = "snacks",
  params = {
    region = { type = "string", default = os.getenv("REGION_ENV_VAR") },
    tier = { type = "string", default = os.getenv("TIER_ENV_VAR") },
    module = { type = "string" },
  },
  builder = function(params)
    return {
      name = "tf apply",
      cmd = "TF_LOG="
        .. tostring(vim.g.TF_LOG)
        .. " ./run.sh apply "
        .. params.module
        .. " "
        .. params.tier
        .. " "
        .. params.region,
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
