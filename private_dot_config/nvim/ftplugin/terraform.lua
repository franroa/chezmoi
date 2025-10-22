vim.keymap.set("n", "<leader>oTP", function()
  require("functions.terraform").apply_action("plan", true)
end, { buffer = true, desc = "Target Plan On Target" })

vim.keymap.set("n", "<leader>oTA", function()
  require("functions.terraform").apply_action("apply", true)
end, { buffer = true, desc = "Target Apply On Target" })

vim.keymap.set("n", "<leader>oTD", function()
  require("functions.terraform").apply_action("destroy", true)
end, { buffer = true, desc = "Target Destroy On Target" })

vim.keymap.set("n", "<leader>oTp", function()
  require("functions.terraform").apply_action("plan", false)
end, { buffer = true, desc = "Target Plan" })

vim.keymap.set("n", "<leader>oTa", function()
  require("functions.terraform").apply_action("apply", false)
end, { buffer = true, desc = "Target Apply" })

vim.keymap.set("n", "<leader>oTd", function()
  require("functions.terraform").apply_action("destroy", false)
end, { buffer = true, desc = "Target Destroy" })
