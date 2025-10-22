local tmpl = {
  name = "Ansible Playbook",
  params = {
    -- playbook = {
    --   type = "enum",
    --   choices = {
    --     "linux_config_alloy_apps.yaml",
    --     "linux_config_alloy_nginx.yaml",
    --     "linux_config_alloy_traces.yaml",
    --     "linux_install_alloy.yaml",
    --     "windows_configure_iis.yaml",
    --     "windows_deploy_alloy.yaml",
    --     "windows_server_configuration.yaml",
    --   },
    --   desc = " -- eu01, ca01, us01",
    --   order = 2, -- determines order of parameters in the UI
    --   optional = false,
    --   default = vim.env.REGION_ENV_VAR,
    -- },
    playbook = {
      type = "string",
      order = 2, -- determines order of parameters in the UI
      optional = false,
    },
    -- password = {
    --   type = "string",
    --   order = 1, -- determines order of parameters in the UI
    --   optional = false,
    -- },
    server = {
      type = "string",
      order = 5, -- determines order of parameters in the UI
      optional = false,
    },
  },
  builder = function(params)
    local cmd_str = "ansible-playbook Alloy/playbooks/"
      .. params.playbook
      .. " -i inventory.yaml  --vault-password-file /home/froa/vault_password_file.sh -e 'target="
      .. params.server
      .. "'"

    return {
      cmd = cmd_str,
      cwd = LazyVim.root.git(),
    }
  end,
}
return tmpl
