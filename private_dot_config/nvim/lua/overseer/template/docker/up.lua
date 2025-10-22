local tmpl = {
  name = "Docker Compose Up",
  builder = function(params)
    return {
      -- name = "Build App " .. require("easy-dotnet").get_debug_dll().relative_project_path:match("([^/]+)$"),
      name = "docker compose up",
      cmd = "docker compose up",
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
