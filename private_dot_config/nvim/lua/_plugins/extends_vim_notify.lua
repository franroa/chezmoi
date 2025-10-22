return {
  {
    "rcarriga/nvim-notify",
    config = function(_, opts)
      local job = require("plenary.job")
      job
        :new({
          command = "curl",
          args = { "https://vtip.43z.one" },
          on_exit = function(j, exit_code)
            local res = table.concat(j:result())
            if exit_code ~= 0 then
              res = "Error fetching tip: " .. res
            end
            require("notify")(res)
          end,
        })
        :start()
    end,
  },
}
