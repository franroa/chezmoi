return {
  "chrisgve/databox.nvim",
  config = function()
    local success, err = require("databox").setup({
      private_key = "~/.config/age/keys.txt",
      public_key = "age1example...", -- Your public key string
      -- Optional: Use rage for better performance
      -- encryption_cmd = "rage -e -r %s",
      -- decryption_cmd = "rage -d -i %s",
    })

    if not success then
      vim.notify("Databox setup failed: " .. err, vim.log.levels.ERROR)
    end
  end,
}
