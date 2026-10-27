local tmpl = {
  name = "Clear Nuget Cache",
  builder = function(params)
    return {
      name = "Clear Nuget Cache In App " .. LazyVim.root.git():match("([^/]+)$"),
      cmd = "dotnet nuget locals all --clear && mkdir /root/.nuget/packages/",
      cwd = require("functions.git_root"),
    }
  end,
}
return tmpl
