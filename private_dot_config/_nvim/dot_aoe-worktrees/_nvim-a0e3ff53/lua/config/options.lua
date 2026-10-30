local opt = vim.opt

opt.termguicolors = true
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldlevelstart = -1
opt.foldenable = true
opt.icm = "split"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

opt.pumblend = 0 -- transparency

opt.spelllang = "en_us"
opt.spell = true

-- opt.scrolloff = math.floor(0.5 * vim.o.lines)
-- opt.scrolloff = 9999 -- this is not working for C-u keymap (now commented)
-- opt.splitkeep = "cursor"
-- views can only be fully collapsed with the global statusline
opt.laststatus = 3
-- Default splitting will cause your main splits to jump when opening an edgebar.
-- To prevent this, set `splitkeep` to either `screen` or `topline`.
opt.splitkeep = "screen"

-- opt.shellcmdflag = "-ic"
--
opt.shell = "bash" -- TODO:make it bash

-- Input Sugesstion (toggle with "<leader>u<tab>")
--   * false: Disable
--   * true:  Enable
vim.g.input_suggestion = true

-- TODO: move all general options here
if vim.g.started_by_firenvim then
  vim.g.vscode = true
  vim.opt.laststatus = 0
end
if vim.env.VSCODE then
  vim.g.vscode = true
end

-- opt.statuscolumn = "%!v:lua.require('functions.statuscolumn').myStatuscolumn()"

opt.showtabline = 2
opt.fileformat = "unix"
-- opt.clipboard = ""
-- opt.clipboard = ""
opt.clipboard = "unnamedplus"
if vim.fn.has("wsl") == 1 then
  if vim.fn.executable("wl-copy") == 0 then
    print("wl-clipboard not found, clipboard integration won't work")
  else
    vim.g.clipboard = {
      name = "wl-clipboard (wsl)",
      copy = {
        ["+"] = "wl-copy --foreground --type text/plain",
        ["*"] = "wl-copy --foreground --primary --type text/plain",
      },
      paste = {
        ["+"] = function()
          return vim.fn.systemlist('wl-paste --no-newline|sed -e "s/\r$//"', { "" }, 1) -- '1' keeps empty lines
        end,
        ["*"] = function()
          return vim.fn.systemlist('wl-paste --primary --no-newline|sed -e "s/\r$//"', { "" }, 1)
        end,
      },
      cache_enabled = true,
    }
  end
end

vim.g.dbs = {
  { name = "dev", url = os.getenv("DB_URL_DEV") },
  { name = "docker", url = os.getenv("DB_URL_LOCAL") },
}
