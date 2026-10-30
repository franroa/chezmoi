local tmpl = {
  name = "Start Local DB",
  builder = function(params)
    return {
      name = "Start Local DB",
      cmd = "fish " .. os.getenv("START_DB_SCRIPT"),
      cwd = os.getenv("START_DB_REPO"),
    }
  end,
}
return tmpl
