local tmpl = {
  name = "Clear Nuget Cache",
  builder = function(params)
    return {
      name = "Clear Nuget Cache In App " .. LazyVim.root.git():match("([^/]+)$"),
      cmd = "dotnet nuget locals all --clear && mkdir /root/.nuget/packages/",
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
