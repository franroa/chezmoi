-- dotnet pack -c Release
local tmpl = {
  name = "Push All Nuget Packages Locally",
  builder = function(params)
    local root_git = LazyVim.root.git()
    local command = "find " .. root_git .. " -type d -name 'Release' -exec find {} -name '*.nupkg' \\;"
    local result = vim.fn.systemlist(command)
    bash_cmd = ""
    for i, res in ipairs(result) do
      if i > 1 then
        bash_cmd = bash_cmd .. " && "
      end
      bash_cmd = bash_cmd .. "dotnet nuget push " .. res .. " --source /root/.nuget/local_source/ --api-key ''"
    end

    return {
      name = "Push nugets locally",
      cmd = bash_cmd,
      cwd = "/",
      components = { { "dependencies", task_names = { "Pack Nugets" } }, "on_exit_set_status", "default" },
    }
  end,
}
return tmpl
