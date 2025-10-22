local M = {}

-- -- Update lua path to ensure modules are found
-- package.path = "/home/froa/Projects/alloy/nvim/lua/?.lua;" .. package.path

local keymaps = require("features.testing.keymaps")

function M.setup()
	keymaps.setup_keymaps()
end

return M
