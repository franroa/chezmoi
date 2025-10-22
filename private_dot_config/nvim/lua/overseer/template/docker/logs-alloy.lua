local tmpl = {
  name = "Docker logs alloy",
  builder = function(params)
    return {
      -- name = "Build App " .. require("easy-dotnet").get_debug_dll().relative_project_path:match("([^/]+)$"),
      name = "docker compose logs alloy",
      cmd = "docker compose logs alloy -f",
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
