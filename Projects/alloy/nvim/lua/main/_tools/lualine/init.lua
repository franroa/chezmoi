--- Lualine integration for Alloy plugin.

local configuration = require("alloy._core.configuration")

local M = {}

--- Get the Alloy status for lualine display.
---
--@return string # Status text to display
---
function M.get_status()
	local config = configuration.resolve_data()
	local text = config.tools.lualine.alloy_status.text

	-- You can add logic here to show different statuses
	-- For example, check if tests are running, if there are errors, etc.

	return text
end

--- Get the color configuration for lualine.
---
--@return string|table # Color specification
---
function M.get_color()
	local config = configuration.resolve_data()
	return config.tools.lualine.alloy_status.color
end

--- Setup function for lualine component.
---
--@param opts table? Optional configuration
--@return table # Lualine component configuration
---
function M.setup(opts)
	opts = opts or {}

	return vim.tbl_extend("force", {
		function()
			return M.get_status()
		end,
		color = function()
			return M.get_color()
		end,
		cond = function()
			-- Only show when in Alloy files
			return vim.bo.filetype == "alloy" or vim.fn.expand("%:e") == "alloy"
		end,
	}, opts)
end

return M
