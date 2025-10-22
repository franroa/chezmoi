local tmpl = {
  name = "Clean .NET App",
  builder = function(params)
    -- local current_file_dir = vim.fn.expand("%:p:h")
    -- local csproj_path = io.popen("ls " .. current_file_dir .. "/*.csproj"):read("*a")
    -- vim.notify(csproj_path)
    return {
      name = "Clean App " .. LazyVim.root.git():match("([^/]+)$"),
      cmd = "dotnet clean",
      -- strategy = "watch",
      -- params = {
      --   file = LazyVim.root.git() .. "/src",
      -- },
      cwd = LazyVim.root.git(),
      -- components = {
      --   { "wait_for_it_if_exists", task_names = {
      --     "Clear Nuget Cache",
      --   } },
      -- },
    }
  end,
}
return tmpl
