local tmpl = {
  name = "Delete Last .Net Migration",
  builder = function(params)
    return {
      name = "Remove Last Migration",
      cmd = "dotnet ef migrations remove --force --project ../"
        .. os.getenv("MIGRATIONS_PROJECT_PREFIX")
        .. ".Infraestructure",
      cwd = LazyVim.root.git() .. "/src/services/" .. os.getenv("MIGRATIONS_PROJECT_PREFIX") .. ".Apply.Migrations",
    }
  end,
}
return tmpl
