local tmpl = {
  name = "Init Local Database With Dev Content",
  builder = function(params)
    return {
      name = "Init Local DB in " .. LazyVim.root.git():match("([^/]+)$"),
      cmd = "mysqldump -u gims -h 127.0.0.1 -P 3307 -p gims2 > output_file.sql",
      cwd = "/",
    }
  end,
}
return tmpl
