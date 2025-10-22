--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---

local configuration = require("main._core.configuration")

local M = {}

-- Automatic initialization (plugin works without setup() call)
configuration.initialize_data_if_needed()

--@param path string The path to the field being validated
--@param tbl table The table to validate
--@see [vim.validate](lua://vim.validate)
--@return boolean is_valid
--@return string|nil error_message
local function validate_path(path, tbl)
	local ok, err = pcall(vim.validate, tbl)
	return ok, err and path .. "." .. err
end

--@param cfg alloy.Configuration
--@return boolean is_valid
--@return string|nil error_message
local function validate_config(cfg)
	local ok, err = validate_path("vim.g.alloy_configuration", {
		loki_url = { cfg.loki_url, "string" },
		manage_loki = { cfg.manage_loki, "boolean" },
		loki_container_name = { cfg.loki_container_name, "string" },
		loki_image = { cfg.loki_image, "string" },
		override_dir_name = { cfg.override_dir_name, "string" },
		override_file_name = { cfg.override_file_name, "string" },
		debug = { cfg.debug, "boolean" },
		use_default_keymaps = { cfg.use_default_keymaps, "boolean" },
		keymaps = { cfg.keymaps, "table" },
		tools = { cfg.tools, "table" },
	})
	return ok, err
end

--- Setup the Alloy plugin with the given configuration.
--- This function is optional - the plugin will work without calling it.
---
--@param opts alloy.Configuration? User configuration options
---
function M.setup(opts)
	opts = opts or {}

	-- Merge installer/user opts into global configuration immediately so defaults are overridden
	if next(opts) then
		configuration.setup(vim.tbl_deep_extend("force", vim.g.alloy_configuration or {}, opts))
	end

	-- Validate final configuration
	local is_valid, error_message = validate_config(configuration.resolve_data())
	if not is_valid then
		vim.notify("Alloy: Invalid configuration - " .. (error_message or "unknown error"), vim.log.levels.ERROR)
		return
	end

	configuration.initialize_data_if_needed()
	require("features").setup()

	-- Install default global keymaps: central module decides whether to apply
	local keymaps = require("main.keymaps")
	-- ensure default keymaps are applied; setup_default_keymaps is idempotent
	keymaps.setup_default_keymaps()
end

return M
