--- All functions and data to help customize `alloy` for this user.
---
--- KEYMAP CONFIGURATION:
--- The default keymaps are defined directly in each keymap module's ACTIONS object:
--- - alloy.keymaps: Global actions that work everywhere in alloy files
--- - features.common.keymaps: Common diagram actions (horizontal/vertical)
--- - features.diagram.keymaps: Actions specific to horizontal diagrams
--- - features.outline.keymaps: Actions specific to vertical diagrams
--- - features.testing.keymaps: Actions specific to testing contexts
---
--- You can override any keymap by setting it in your configuration:
---   keymaps = {
---     ["create-pipeline-diagram"] = { "n", "<leader>P" }, -- Change key
---     ["show-help"] = false,                              -- Disable keymap
---     ["custom-action"] = { "n", "<leader>ca" },          -- Add custom keymap
---   }

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_alloy = false

--@type alloy.Configuration
M.DATA = {}

--@class alloy.Configuration
--@field loki_url string URL for Loki instance
--@field manage_loki boolean Whether to manage Loki container
--@field loki_container_name string Name of Loki container
--@field loki_image string Docker image for Loki
--@field override_dir_name string Directory name for test overrides
--@field override_file_name string File name for test overrides
--@field debug boolean Enable debug mode
--@field use_default_keymaps boolean Whether to use default keymaps
--@field keymaps alloy.KeymapConfiguration Keymap configuration
--@field tools alloy.ToolsConfiguration Tool integrations

--@class alloy.KeymapConfiguration
--@field [string] {string, string} Action name to {mode, key} mapping

--@class alloy.ToolsConfiguration
--@field lualine alloy.LualineConfiguration? Lualine integration
--@field telescope alloy.TelescopeConfiguration? Telescope integration

--@class alloy.LualineConfiguration
--@field alloy_status alloy.LualineDisplay Alloy status display

--@class alloy.TelescopeConfiguration
--@field components string[] Component list for telescope

--@class alloy.LualineDisplay
--@field color string|table Color specification
--@field text string Display text

--@type alloy.Configuration
local _DEFAULTS = {
	loki_url = "http://localhost:3100",
	manage_loki = true,
	loki_container_name = "neovim-loki-test",
	loki_image = "grafana/loki:3.0.0",
	override_dir_name = ".alloy_tests",
	override_file_name = "localtest.alloy",
	debug = false,
	use_default_keymaps = true,
	keymaps = {},
	tools = {
		lualine = {
			alloy_status = {
				color = "Normal",
				text = " Alloy",
			},
		},
		telescope = {
			components = {},
		},
	},
}

--- Extract default keymaps from all ACTIONS objects
local function get_all_default_keymaps()
	local defaults = {}

	-- Get defaults from all keymap modules via centralized registry
	local features = require("features")
	local keymap_modules = features.get_keymap_modules()

	for _, module_name in ipairs(keymap_modules) do
		local ok, module = pcall(require, module_name)
		if ok and module.get_actions then
			local actions = module.get_actions()
			for action_id, action_def in pairs(actions) do
				if action_def.default then
					defaults[action_id] = action_def.default
				end
			end
		end
	end

	return defaults
end

function M.get_defaults()
	local defaults = vim.deepcopy(_DEFAULTS)
	defaults.keymaps = get_all_default_keymaps()
	return defaults
end

--- Setup `alloy` for the first time, if needed.
function M.initialize_data_if_needed()
	if vim.g.loaded_alloy then
		return
	end

	local defaults = M.get_defaults()
	M.DATA = vim.tbl_deep_extend("force", defaults, vim.g.alloy_configuration or {})
	vim.g.loaded_alloy = true
end

--- Setup configuration explicitly with user's config.
---@param user_cfg alloy.Configuration?
function M.setup(user_cfg)
	vim.g.alloy_configuration = user_cfg or {}
	local defaults = M.get_defaults()
	M.DATA = vim.tbl_deep_extend("force", defaults, vim.g.alloy_configuration)
	vim.g.loaded_alloy = true
end

--- Merge `data` with the user's current configuration.
---
--@param data alloy.Configuration? All extra customizations for this plugin.
--@return alloy.Configuration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
	M.initialize_data_if_needed()
	return vim.tbl_deep_extend("force", M.DATA, data or {})
end

--- Get a configuration value by key.
---
--@param key string The configuration key to retrieve
--@return any # The configuration value
---
function M.get(key)
	M.initialize_data_if_needed()
	return M.DATA[key]
end

--- Get a nested configuration value using dot notation.
---
--@param key_path string The configuration key path (e.g., "tools.lualine.alloy_status.color")
--@return any # The configuration value
---
function M.get_nested(key_path)
	M.initialize_data_if_needed()
	local keys = vim.split(key_path, ".", { plain = true })
	local value = M.DATA

	for _, key in ipairs(keys) do
		if type(value) == "table" and value[key] ~= nil then
			value = value[key]
		else
			return nil
		end
	end

	return value
end

--- Check if a feature is enabled.
---
--@param feature string The feature name
--@return boolean # Whether the feature is enabled
---
function M.is_enabled(feature)
	local value = M.get(feature)
	return value ~= false and value ~= nil
end

return M
