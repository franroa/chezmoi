local M = {}

local utils = require("core.utils")

local ns_id_override_icon = utils.create_namespace("AlloyOverrideIcon")

function M.clear_override_icons_in_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id_override_icon, 0, -1)
	vim.notify("Cleared test override icons.", vim.log.levels.INFO)
end

return M