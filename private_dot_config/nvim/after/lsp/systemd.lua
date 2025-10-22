return {
  filetypes = {
    "systemd",
  },
  name = "systemd",
  cmd = {
    "/home/froa/Projects/tools/systemd-lsp/target/release/systemd-lsp",
  },
  capabilities = vim.lsp.protocol.make_client_capabilities(),
}
