local M = {}

local FEATURE_REGISTRY = {
	{
		name = "alloy.keymaps",
		module = "main.keymaps",
		setup_function = nil,
		has_keymaps = true,
	},
	{
		name = "diagram", 
		module = "features.diagram",
		setup_function = "setup",
		has_keymaps = true,
		keymap_module = "features.diagram.keymaps",
	},
	{
		name = "outline",
		module = "features.outline", 
		setup_function = "setup",
		has_keymaps = true,
		keymap_module = "features.outline.keymaps",
	},
	{
		name = "testing",
		module = "features.testing",
		setup_function = "setup", 
		has_keymaps = true,
		keymap_module = "features.testing.keymaps",
	},
	{
		name = "common",
		module = "features.common",
		setup_function = "setup",
		has_keymaps = true,
		keymap_module = "features.common.keymaps",
	},
}

function M.get_feature_registry()
	return FEATURE_REGISTRY
end

function M.get_keymap_modules()
	local keymap_modules = {}
	for _, feature in ipairs(FEATURE_REGISTRY) do
		if feature.has_keymaps then
			local module_name = feature.keymap_module or feature.module
			table.insert(keymap_modules, module_name)
		end
	end
	return keymap_modules
end

function M.setup()
	for _, feature in ipairs(FEATURE_REGISTRY) do
		if feature.setup_function then
			local ok, module = pcall(require, feature.module)
			if ok and module and module[feature.setup_function] then
				module[feature.setup_function]()
			end
		end
	end
end

return M
