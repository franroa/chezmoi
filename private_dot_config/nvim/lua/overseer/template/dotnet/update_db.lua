local tmpl = {
  name = "Update .Net Database",
  builder = function(params)
    return {
      name = "Update Database" .. os.getenv("MIGRATIONS_PROJECT_PREFIX"),
      cmd = "dotnet ef database update",
      cwd = require("functions.git_root")
        .. "/src/services/"
        .. os.getenv("MIGRATIONS_PROJECT_PREFIX")
        .. ".Apply.Migrations",
    }
  end,
}
return tmpl
