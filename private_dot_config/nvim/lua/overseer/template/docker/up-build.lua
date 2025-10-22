local tmpl = {
  name = "Docker Compose Up --Build",
  builder = function(params)
    return {
      -- name = "Build App " .. require("easy-dotnet").get_debug_dll().relative_project_path:match("([^/]+)$"),
      name = "docker compose up --build",
      cmd = "docker compose up --watch --build basicservice",
      components = {
        "default",
        -- "show_spinner",
        { "unique", replace = true },
      },
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
