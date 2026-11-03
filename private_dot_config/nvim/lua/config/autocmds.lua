-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.lsp.enable("river")

-- systemd unit files (after/lsp/systemd.lua), only when the locally built server exists
if vim.fn.executable("/home/froa/Projects/tools/systemd-lsp/target/release/systemd-lsp") == 1 then
  vim.lsp.enable("systemd")
end

-- values.tpl & co. are terraform templatefile() inputs: `%{~ if ~}` directives are not valid
-- yaml, so keep yamlls (schemas, completion, hover) but drop its syntax diagnostics.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("tftpl_yamlls_diagnostics", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == "yamlls" and vim.api.nvim_buf_get_name(ev.buf):match("%.tpl$") then
      vim.diagnostic.enable(false, { bufnr = ev.buf, ns_id = vim.lsp.diagnostic.get_namespace(client.id) })
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("tftpl_yaml_parse", { clear = true }),
  pattern = "yaml",
  callback = function(ev)
    if vim.api.nvim_buf_get_name(ev.buf):match("%.tpl$") then
      -- after LazyVim's own FileType handler has started the parser
      vim.schedule(function()
        require("functions.tftpl").attach(ev.buf)
      end)
    end
  end,
})

-- grey UI groups (line numbers, whitespace, ...) turn yellow on the clusters where a
-- mistake is expensive: technosylva sandbox/test/live and platform test/live. TSYL_* are set by
-- config.fish (change_tsyl_env_from_cluster) and exported to the shell.
-- kube-switch.sh pushes the new TSYL_* into running nvims (--remote-expr) and then fires
-- the User KubeClusterChanged autocmd, so the check re-runs on the switch itself.
local grey_groups = { "LineNr", "LineNrAbove", "LineNrBelow", "CursorLineNr", "NonText", "Whitespace", "EndOfBuffer", "FoldColumn" }
local yellow = 0xe0af68 -- tokyonight yellow
local saved = nil -- original attrs of grey_groups while painted

local function is_warning_cluster(domain, tier)
  return (domain == "technosylva" and (tier == "sandbox" or tier == "test" or tier == "live"))
    or (domain == "platform" and (tier == "test" or tier == "live"))
end

local function paint(on)
  if on and not saved then
    saved = {}
    for _, group in ipairs(grey_groups) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      saved[group] = vim.deepcopy(hl)
      hl.fg = yellow
      vim.api.nvim_set_hl(0, group, hl)
    end
  elseif not on and saved then
    for group, hl in pairs(saved) do
      vim.api.nvim_set_hl(0, group, hl)
    end
    saved = nil
  end
end

local function refresh()
  paint(is_warning_cluster(vim.env.TSYL_DOMAIN, vim.env.TSYL_TIER))
end

local kube_group = vim.api.nvim_create_augroup("kube_cluster_yellow_grey", { clear = true })

-- a colorscheme load resets the groups, so the saved attrs are stale
vim.api.nvim_create_autocmd("ColorScheme", {
  group = kube_group,
  callback = function()
    saved = nil
    refresh()
  end,
})

-- fired by kube-switch.sh right after it pushes the new TSYL_* into this instance
vim.api.nvim_create_autocmd("User", {
  group = kube_group,
  pattern = "KubeClusterChanged",
  callback = refresh,
})

refresh()
