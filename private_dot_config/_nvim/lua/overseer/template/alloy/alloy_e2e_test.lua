return {
  name = "Alloy E2E Test",
  builder = function()
    -- Get the full path of the buffer containing the Alloy config
    local file_path = vim.api.nvim_buf_get_name(0)

    return {
      cmd = { "nvim", "--headless" },
      args = {
        "-c",
        -- This command will load your test runner script and execute it
        string.format("lua require('functions.alloy_e2e_test').run('%s')", vim.fn.escape(file_path, " ")),
        "--",
        file_path,
      },
      -- Optional: Set the working directory to your project root
      cwd = vim.fn.getcwd(),
    }
  end,
  -- The parser transforms the output into a structured result
  parser = require("overseer.parser").decode_json,
}
