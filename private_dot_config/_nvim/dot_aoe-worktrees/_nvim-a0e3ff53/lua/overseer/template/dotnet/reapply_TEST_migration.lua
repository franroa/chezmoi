local tmpl = {
  name = "Reapply TEST .Net Migration",
  builder = function(params)
    return {
      name = "Reapply TEST Migration" .. os.getenv("MIGRATIONS_PROJECT_PREFIX"),
      cmd = "dotnet ef migrations remove --force --project ../"
        .. os.getenv("MIGRATIONS_PROJECT_PREFIX")
        .. ".Infraestructure && dotnet ef migrations add TEST --project ../"
        .. os.getenv("MIGRATIONS_PROJECT_PREFIX")
        .. ".Infraestructure  && dotnet ef database update",
      -- cmd = "dotnet ef migrations add TEST --project ../"
      --   .. os.getenv("MIGRATIONS_PROJECT_PREFIX")
      --   .. ".Infraestructure || dotnet ef migrations remove --force --project ../"
      --   .. os.getenv("MIGRATIONS_PROJECT_PREFIX")
      --   .. ".Infraestructure && dotnet ef migrations add TEST --project ../"
      --   .. os.getenv("MIGRATIONS_PROJECT_PREFIX")
      --   .. ".Infraestructure  && dotnet ef database update",
      cwd = LazyVim.root.git() .. "/src/services/" .. os.getenv("MIGRATIONS_PROJECT_PREFIX") .. ".Apply.Migrations",
    }
  end,
}
return tmpl
