local tmpl = {
  name = "Create .Net Migration",
  params = {
    migration_name = { type = "string" },
  },
  builder = function(params)
    return {
      name = "Create Migration " .. params.migration_name,
      cmd = "dotnet ef migrations add " .. params.migration_name .. " --project ../" .. os.getenv(
        "MIGRATIONS_PROJECT_PREFIX"
      ) .. ".Infraestructure",
      cwd = LazyVim.root.git() .. "/src/services/" .. os.getenv("MIGRATIONS_PROJECT_PREFIX") .. ".Apply.Migrations",
    }
  end,
}
return tmpl
