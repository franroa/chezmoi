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
