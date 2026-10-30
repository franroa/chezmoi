local tmpl = {
  name = "Pack Nugets",
  builder = function(params)
    return {
      name = "Pack Nugets " .. LazyVim.root.git():match("([^/]+)$"),
      cmd = "dotnet pack",
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
