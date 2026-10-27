local tmpl = {
  name = "Pack Nugets",
  builder = function(params)
    return {
      name = "Pack Nugets " .. require("functions.git_root"):match("([^/]+)$"),
      cmd = "dotnet pack",
      cwd = require("functions.git_root"),
    }
  end,
}
return tmpl
