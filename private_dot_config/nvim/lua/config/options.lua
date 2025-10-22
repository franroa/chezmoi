-- local opt = vim.opt
--
-- -- opt.wrap = true
-- -- opt.breakindent = true
-- -- -- opt.showbreak = string.rep(" ", 3) -- Make it so that long lines wrap smartly
-- -- opt.showbreak = "▋ "
-- -- opt.linebreak = true
--
-- opt.termguicolors = true
-- -- opt.foldcolumn = "1"
-- -- opt.foldlevel = 99
-- -- opt.foldlevelstart = -1
-- -- opt.foldenable = true
-- -- opt.icm = "split"
-- -- opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- -- Nice and simple folding:
-- --
-- opt.eol = true
-- opt.fixeol = true
-- vim.opt.foldmethod = "expr"
-- -- vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- opt.foldexpr = "v:lua.require'lazyvim.util'.ui.foldexpr()"
-- vim.opt.foldcolumn = "1"
-- vim.o.fillchars = [[eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸]]
-- vim.opt.foldtext = "test"
-- vim.opt.foldlevel = 99
-- -- Using ufo provider need a large value, feel free to decrease the value
-- vim.opt.foldlevelstart = 99
-- vim.opt.foldnestmax = 6
-- vim.opt.foldenable = true
-- -- Faster fold updates
-- vim.opt.foldopen = "block,hor,insert,jump,mark,percent,quickfix,search,tag,undo"
-- vim.opt.foldclose = "all"
-- -- vim.o.foldcolumn = "1" -- Muestra una columna a la izquierda para el plegado
-- -- vim.o.foldlevel = 99 -- Inicia con todos los pliegues abiertos
-- -- vim.o.foldlevelstart = 99
-- -- vim.o.foldenable = true
-- -- vim.o.foldenable = true
-- -- vim.o.foldlevel = 99
-- -- vim.o.foldmethod = "expr"
-- -- vim.o.foldexpr = "vim.treesitter.foldexpr()"
-- -- vim.opt.foldlevelstart = 99
-- -- vim.o.foldtext = ""
-- -- vim.opt.foldcolumn = "0"
-- -- vim.opt.number = true
-- -- vim.opt.textwidth = 0
-- -- vim.opt.wrapmargin = 0
-- -- vim.opt.wrap = true
-- -- vim.opt.linebreak = true
--
--
-- opt.pumblend = 0 -- transparency
--
-- opt.spelllang = "en_us"
-- opt.spell = true
--
-- -- vim.opt.diffopt = "inline:word"
--
-- -- opt.scrolloff = math.floor(0.5 * vim.o.lines)
-- -- opt.scrolloff = 9999 -- this is not working for C-u keymap (now commented)
-- -- opt.splitkeep = "cursor"
-- -- views can only be fully collapsed with the global statusline
-- opt.laststatus = 3
-- -- Default splitting will cause your main splits to jump when opening an edgebar.
-- -- To prevent this, set `splitkeep` to either `screen` or `topline`.
-- opt.splitkeep = "screen"
--
-- -- opt.shellcmdflag = "-ic"
-- --
-- -- opt.shell = "fish" -- TODO:make it bash
-- opt.shell = "bash" -- TODO:make it bash
--
-- -- Input Sugesstion (toggle with "<leader>u<tab>")
-- --   * false: Disable
-- --   * true:  Enable
-- vim.g.input_suggestion = true
--
-- -- TODO: move all general options here
-- if vim.g.started_by_firenvim then
--   vim.g.vscode = true
--   vim.opt.laststatus = 0
-- end
-- if vim.env.VSCODE then
--   vim.g.vscode = true
-- end
--
-- -- opt.statuscolumn = "%!v:lua.require('functions.statuscolumn').myStatuscolumn()"
--
-- opt.showtabline = 2
-- -- opt.fileformat = "unix"
-- -- opt.fileformats = "unix,dos"
-- -- opt.clipboard = ""
-- -- opt.clipboard = ""
-- -- opt.clipboard = "unnamedplus"
-- if vim.fn.has("wsl") == 1 then
--   if vim.fn.executable("wl-copy") == 0 then
--     print("wl-clipboard not found, clipboard integration won't work")
--   else
--     -- vim.g.clipboard = {
--     --   name = "wl-clipboard (wsl)",
--     --   copy = {
--     --     ["+"] = "wl-copy --foreground --type text/plain",
--     --     ["*"] = "wl-copy --foreground --primary --type text/plain",
--     --   },
--     --   paste = {
--     --     ["+"] = function()
--     --       return vim.fn.systemlist('wl-paste --no-newline|sed -e "s/\r$//"', { "" }, 1) -- '1' keeps empty lines
--     --     end,
--     --     ["*"] = function()
--     --       return vim.fn.systemlist('wl-paste --primary --no-newline|sed -e "s/\r$//"', { "" }, 1)
--     --     end,
--     --   },
--     --   cache_enabled = true,
--     -- }
--   end
-- end
--
local db_entries = {}

-- Only add entries if environment variables are set
if os.getenv("DB_URL_LOCAL") then
  table.insert(db_entries, { name = "docker", url = os.getenv("DB_URL_LOCAL") })
end

if os.getenv("DB_TUNNEL_PASS") then
  table.insert(db_entries, {
    name = "tunnel",
    url = "sqlserver://riskgrafanamonitor:" .. os.getenv("DB_TUNNEL_PASS") .. "@localhost:14333",
  })
end

vim.g.dbs = db_entries

local arrows = {
  right = "",
  left = "",
  up = "",
  down = "",
}
vim.o.foldcolumn = "1"
vim.o.foldlevelstart = 99
vim.wo.foldtext = ""
vim.opt.fillchars = {
  fold = " ",
  foldclose = arrows.right,
  foldopen = arrows.down,
  foldsep = " ",
  foldinner = " ",
}

vim.opt.fillchars:append({ fold = " " })
vim.opt.fillchars:append({ diff = "╱" })
vim.opt.diffopt = {
  "internal",
  "filler",
  "closeoff",
  "context:12",
  "algorithm:histogram",
  "linematch:200",
  "indent-heuristic",
}
vim.api.nvim_set_hl(0, "DiffAdd", { fg = "gray", bg = "#2e4b2e" })
vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#463d3d", bg = "#292e42" })
vim.api.nvim_set_hl(0, "DiffChange", { fg = "gray", bg = "#45565c" })
vim.api.nvim_set_hl(0, "DiffText", { fg = "gray", bg = "#996d74" })
vim.api.nvim_set_hl(0, "DiffviewDiffAdd", { fg = "gray", bg = "#2e4b2e" })
vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { fg = "#463d3d", bg = "#292e42" })
vim.api.nvim_set_hl(0, "DiffviewDiffChange", { fg = "gray", bg = "#45565c" })
vim.api.nvim_set_hl(0, "DiffviewDiffText", { fg = "gray", bg = "#996d74" })
--
-- vim.o.completeopt = "menu,menuone"
-- vim.opt.virtualedit = "all"
