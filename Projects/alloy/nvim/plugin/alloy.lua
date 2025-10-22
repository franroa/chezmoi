--- All `alloy` command definitions.
--- Plugin automatically initializes without requiring a setup() call.

-- Initialize configuration lazily
local function ensure_initialized()
	if not vim.g.loaded_alloy then
		local configuration = require("main._core.configuration")
		configuration.initialize_data_if_needed()
	end
end

--@class AlloySubcommand
--@field impl fun(args: string[], opts: table) The command implementation
--@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback

--@type table<string, AlloySubcommand>
local function merge_keymap_actions()
	local features = require("features")
	local keymap_modules = features.get_keymap_modules()
	local merged = {}
	for _, mod in ipairs(keymap_modules) do
		local ok, m = pcall(require, mod)
		if ok and m and m.get_actions then
			local acts = m.get_actions()
			for k, v in pairs(acts) do
				merged[k] = v
			end
		end
	end
	return merged
end

local subcommand_tbl = vim.tbl_extend("force", merge_keymap_actions(), {})

--@param opts table
local function alloy_cmd(opts)
	local fargs = opts.fargs
	local subcommand_key = fargs[1]
	local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
	local subcommand = subcommand_tbl[subcommand_key]

	if not subcommand then
		vim.notify("Alloy: Unknown command: " .. (subcommand_key or ""), vim.log.levels.ERROR)
		return
	end

	subcommand.func(args, opts)
end

-- Create the main Alloy command
vim.api.nvim_create_user_command("Alloy", alloy_cmd, {
	nargs = "+",
	desc = "Alloy pipeline management commands",
	complete = function(arg_lead, cmdline, _)
		local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Alloy[!]*%s(%S+)%s(.*)$")
		if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete then
			return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
		end

		if cmdline:match("^['<,'>]*Alloy[!]*%s+%w*$") then
			local subcommand_keys = vim.tbl_keys(subcommand_tbl)
			return vim.iter(subcommand_keys)
				:filter(function(key)
					return key:find(arg_lead) ~= nil
				end)
				:totable()
		end
	end,
	bang = true,
})
