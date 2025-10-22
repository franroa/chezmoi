-- TODO: https://alpha2phi.medium.com/neovim-for-beginners-3rd-party-tools-c4a5148e501c
-- https://alpha2phi.medium.com/neovim-for-beginners-cheatsheet-and-coding-assistant-137d5a15c934

local split = require("functions.utils").split

function GetAllTerminals()
  return require("toggleterm.terminal").get_all(true)
end

function GetTerminalById(id)
  return require("toggleterm.terminal").get(id)
  -- local terms_table = require('toggleterm.terminal').get_all(true)
  -- for _, term in pairs(terms_table) do
  --   if term.name == name then
  --     return term
  --   end
  -- end
  -- return nil
end

function GetCurrentTerminal()
  return require("toggleterm.terminal").get(require("toggleterm.terminal").get_focused_id())
  -- local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  -- local splited_buf_name = split(buf_name, "(")
  -- if splited_buf_name[2] == nil then
  --   return nil
  -- end
  -- local term_name = "(" .. splited_buf_name[2]
  -- local current_term = GetTerminalByName(term_name)
  -- if current_term == nil then
  -- end
end

function GetCurrentOrPreviousTerminal()
  local focused_term = require("toggleterm.terminal").get_focused_id()
  if focused_term == nil then
    if vim.g.previous_termina then
      return vim.g.previous_termina
    end
    return nil
  end

  return require("toggleterm.terminal").get(focused_term)
  -- local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  -- local splited_buf_name = split(buf_name, "(")
  --
  -- if splited_buf_name[2] == nil then
  --   if vim.g.previous_terminal then
  --     return vim.g.previous_terminal
  --   end
  --   return nil
  -- end
  --
  -- local term_name = "(" .. splited_buf_name[2]
  --
  -- local term = GetTerminalByName(term_name)
  --
  -- if term then
  --   return term
  -- end
  --
  -- return nil
end

function GetWindowsOfOpenedTerminals()
  local terms_table = GetAllTerminals()
  local tab = {}
  for _, term in pairs(terms_table) do
    vim.notify(tostring(term:is_open()))
    if term:is_open() then
      table.insert(tab, term.window)
    end
  end
  return tab
end

function OpenOrCreateTerminal(opts)
  local namespace = vim.fn.system("echo -n $(kubie info ns 2>/dev/null)")
  local new_name = opts.name
  local display_name = "normal"
  if namespace ~= "" and opts.name ~= "k9s" or opts.non_k8s ~= false then
    new_name = "(" .. namespace .. ") " .. opts.name
    display_name = "kubernetes"
  end

  if opts.name == "k9s" then
    display_name = "k9s"
  end

  local term = GetTerminalById(new_name)
  if term ~= nil then
    vim.notify("There is already a terminal with that name!", "warning")
    for _, other_term in pairs(GetAllTerminals()) do
      if term.name ~= other_term.name then
        term:close()
      end
    end
    if term:is_open() == false then
      term:toggle()
    end
    term:focus()
    return term
  end

  local Terminal = require("toggleterm.terminal").Terminal

  for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if string.find(vim.api.nvim_buf_get_name(bufnr), new_name) then
      vim.api.nvim_buf_delete(bufnr, {})
      break
    end
  end

  if vim.g.kubernetes_cluster == nil then
    require("functions.kubernetes").UpdateGlobalValues()
  end

  local cmd = "CLUSTER="
    .. vim.g.kubernetes_cluster
    .. " NAMESPACE="
    .. vim.g.kubernetes_namespace
    .. " "
    .. opts.instruction

  local customTerminal = Terminal:new({
    on_create = function(term)
      term.name = new_name
      vim.api.nvim_buf_set_name(term.bufnr, new_name)
    end,
    cmd = cmd,
    -- float_opts = {
    --   border = "double",
    --   width = function() return vim.o.columns end,
    --   height = function() return vim.o.lines end
    -- },
    dir = opts.dir == nil and require("lazyvim.util").root.get() or opts.dir,
    direction = opts.direction == nil and "horizontal" or opts.direction,
    hidden = false,
    close_on_exit = false,
    name = new_name,
    display_name = display_name,
    shell = opts.shell == nil and "bash" or opts.shell,
  })
  customTerminal:toggle()
  return customTerminal
end

return {
  -- amongst your other plugins
  {
    "akinsho/toggleterm.nvim",
    -- dependencies = {
    --   -- which key integration
    --   {
    --     "folke/which-key.nvim",
    --     opts = function(_, opts)
    --       if require("lazyvim.util").has("noice.nvim") then
    --         opts.spec["<leader>ft"] = { name = "+terminal" }
    --         opts.spec["<leader>ftf"] = { name = "+format" }
    --       end
    --     end,
    --   },
    -- },
    keys = {
      {
        "<leader>T",
        function()
          vim.cmd("ToggleTerm")
        end,
        desc = "lazygit",
      },
      {
        "<leader>ftl",
        function()
          local lg_cmd = "lazygit -w $PWD"
          if vim.v.servername ~= nil then
            lg_cmd =
              string.format("NVIM_SERVER=%s lazygit -ucf ~/.config/lazygit/lazygit.toml -w $PWD", vim.v.servername)
          end

          -- TODO: https://github.com/mhinz/neovim-remote
          -- vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"

          OpenOrCreateTerminal({ instruction = lg_cmd, name = "lazygit", direction = "tab" })
        end,
        desc = "lazygit",
      },
      {
        "<leader>ftv",
        function()
          OpenOrCreateTerminal({ instruction = "visidata", name = "visidata", direction = "tab" })
        end,
        desc = "Visidata", -- https://github.com/ClementTsang/bottom#cargo
      },
      {
        "<leader>ftw",
        function()
          OpenOrCreateTerminal({ instruction = "git cz", name = "comittizen", direction = "tab" })
        end,
        desc = "Commitizzen", -- https://github.com/ClementTsang/bottom#cargo
      },
      {
        "<leader>ftb",
        function()
          OpenOrCreateTerminal({ instruction = "bottom", name = "bottom", direction = "tab" })
        end,
        desc = "Bottom", -- https://github.com/ClementTsang/bottom#cargo
      },
      {
        "<leader>ftt",
        function()
          OpenOrCreateTerminal({ instruction = "tokei", name = "tokei", direction = "tab" })
        end,
        desc = "tokei - Project Info",
      },
      {
        "<leader>ftd",
        function()
          OpenOrCreateTerminal({ instruction = "lazydocker", name = "lazydocker", direction = "tab" })
        end,
        desc = "lazydocker",
      },
      {
        "<leader>ftc",
        function()
          OpenOrCreateTerminal({ instruction = "ctop", name = "ctop", direction = "tab" })
        end,
        desc = "ctop",
      },
      {
        "<leader>ftg",
        function()
          OpenOrCreateTerminal({ instruction = "gitlab-ci-local", name = "gitlab-local", direction = "float" })
        end,
        desc = "gitlab local",
      },
    },
    version = "*",
    config = true,
  },
}
