local tmpl = {
  name = "Run .NET App",
  builder = function(params)
    return {
      name = "Run App " .. LazyVim.root.git():match("([^/]+)$"),
      -- cmd = "dotnet run --project " .. os.getenv("RUNNABLE_PROJECT"),
      cmd = "dotnet run",
      -- strategy = "watch",
      -- params = {
      --   file = LazyVim.root.git() .. "/src",
      -- },
      cwd = LazyVim.root.git(),
      components = {
        -- We don't care to keep this around as long as most tasks
        { "restart_on_save", paths = { LazyVim.root.git() } },
        "default",
        { "unique", replace = true },
      },
    }
  end,
}
return tmpl
