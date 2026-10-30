-- https://www.youtube.com/watch?v=rerTvidyz-0
local tmpl = {
  name = "Run skaffold dev",
  builder = function(params)
    return {
      -- name = "Build App " .. require("easy-dotnet").get_debug_dll().relative_project_path:match("([^/]+)$"),
      name = "skaffold",
      cmd = "skaffold dev",
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
