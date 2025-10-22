local tmpl = {
  name = "Restore .NET App",
  builder = function(params)
    return {
      name = "Restore .NET App",
      cmd = "dotnet restore --configfile " .. os.getenv("NUGET_CONFIG"),
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
