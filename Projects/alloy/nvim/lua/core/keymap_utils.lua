local configuration = require("main._core.configuration")

local M = {}

-- internal queue for registrations called before setup
M._queue = {}
M._ready = false
M._cfg_keymaps = nil

-- The default apply function is a direct keymap set. This is used for programmatic registrations.
local function direct_apply_fn(mode, lhs, rhs, opts)
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- internal map application engine
local function map_with_config(default_maps, config_keymaps, apply_fn)
	apply_fn = apply_fn or direct_apply_fn

	if not config_keymaps then
		return {}
	end

	local applied = {}

	for _, m in ipairs(default_maps) do
		local cfg_entry = config_keymaps[m.id]

		-- If user has set the keymap to `false`, disable it.
		if cfg_entry == false then
			goto continue
		end

		local mode = m.mode
		local lhs = m.lhs
		local opts = vim.tbl_deep_extend("force", { silent = true, desc = m.desc }, m.opts or {})

		-- If user has provided an override table, apply it.
		if type(cfg_entry) == "table" and #cfg_entry >= 2 then
			mode = cfg_entry[1] or mode
			lhs = cfg_entry[2] or lhs
			if type(cfg_entry[3]) == "table" then
				opts = vim.tbl_deep_extend("force", opts, cfg_entry[3])
			end
		end

		if mode and lhs and lhs ~= "" then
			-- Guard: ensure rhs is present
			if m.rhs == nil then
				vim.notify(
					string.format("Alloy: keymap '%s' has no action function (rhs is nil)", m.id),
					vim.log.levels.WARN
				)
				goto continue
			end
			apply_fn(mode, lhs, m.rhs, opts)
			table.insert(applied, { id = m.id, mode = mode, lhs = lhs, rhs = m.rhs, opts = opts, desc = m.desc })
		end

		::continue::
	end

	return applied
end

-- safe, lightweight register that queues until setup runs
function M.register(maps)
	if not maps then
		return
	end
	-- Normalize single map to list
	if maps.id then
		maps = { maps }
	end
	-- If setup already ran, apply maps immediately respecting config
	if M._ready then
		map_with_config(maps, M._cfg_keymaps or false, direct_apply_fn)
		return
	end
	-- Otherwise, append to queue but avoid duplicates by id
	local existing_ids = {}
	for _, q in ipairs(M._queue) do
		existing_ids[q.id] = true
	end
	for _, m in ipairs(maps) do
		if not existing_ids[m.id] then
			table.insert(M._queue, m)
			existing_ids[m.id] = true
		end
	end
end

local function build_default_maps_from_actions(KEYMAP_ACTIONS, base_opts)
	base_opts = base_opts or {}
	-- Fetch the default keymap definitions
	local default_keymaps = configuration.get_defaults().keymaps
	local maps_to_create = {}

	for id, action in pairs(KEYMAP_ACTIONS) do
		-- Start with the plugin's hardcoded defaults
		local default_map = default_keymaps[id]
		if default_map then
			local final_opts = vim.tbl_deep_extend("force", base_opts, default_map[3] or {})
			table.insert(maps_to_create, {
				id = id,
				mode = default_map[1],
				lhs = default_map[2],
				rhs = action.func,
				opts = final_opts,
				desc = action.desc,
			})
		end
	end
	return maps_to_create
end

-- expose builder for external use
M.build_default_maps_from_actions = build_default_maps_from_actions

function M.setup_default_keymaps(KEYMAP_ACTIONS, base_opts)
	local cfg = configuration.resolve_data()

	-- Only set global config on the initial, non-buffer-specific setup
	if not base_opts then
		M._cfg_keymaps = cfg.keymaps
		M._ready = true
	end

	if not cfg.use_default_keymaps then
		-- Only clear the queue on the initial setup
		if not base_opts then
			M._queue = {}
		end
		return
	end

	local default_maps = build_default_maps_from_actions(KEYMAP_ACTIONS, base_opts)
	local apply_fn

	if base_opts then
		-- This is a buffer-local setup, so apply keymaps directly.
		apply_fn = direct_apply_fn
	else
		-- This is the global setup, use an autocommand to apply keymaps to alloy files.
		local augroup = vim.api.nvim_create_augroup("AlloyGlobalKeymaps", { clear = true })
		apply_fn = function(mode, lhs, rhs, opts)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "alloy",
				group = augroup,
				callback = function(args)
					local map_opts = vim.tbl_deep_extend("force", opts, { buffer = args.buf })
					vim.keymap.set(mode, lhs, rhs, map_opts)
				end,
			})
		end
	end

	-- Apply the keymaps using the chosen apply function.
	map_with_config(default_maps, cfg.keymaps, apply_fn)

	-- Also register the built maps so later register() calls merge instead of override
	-- convert applied maps into the queued format (id/mode/lhs/rhs/opts/desc)
	if default_maps and #default_maps > 0 then
		-- If base_opts present (buffer-local), register those maps to ensure merging
		if base_opts then
			M.register(default_maps)
		else
			-- For global maps, register the defaults too so register() can dedupe
			M.register(default_maps)
		end
	end

	-- Only flush the queue on the initial global setup.
	if not base_opts and M._queue and #M._queue > 0 then
		map_with_config(M._queue, cfg.keymaps, direct_apply_fn)
		M._queue = {}
	end
end

return M
