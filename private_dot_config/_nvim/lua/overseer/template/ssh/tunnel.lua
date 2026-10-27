-- https://www.youtube.com/watch?v=rerTvidyz-0
local tmpl = {
  name = "SSH Tunnel",
  strategy = "snacks",
  params = {
    host = { type = "string" },
  },
  builder = function(params)
    return {
      name = "ssh tunnel",
      cmd = " ssh -N " .. params.host,
      cwd = require("functions.git_root"),
    }
  end,
}
return tmpl
