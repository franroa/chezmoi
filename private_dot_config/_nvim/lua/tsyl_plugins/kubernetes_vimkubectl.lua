function GetPods()
  return vim.fn.system('echo -n $(kubectl get pods --no-headers  -o custom-columns=":metadata.name")')
end

function ExecuteFunctionFromSelect(opts)
  local select_table = {}
  for element in string.gmatch(opts.select_choices, "([^ ]+)") do
    table.insert(select_table, element)
  end

  vim.ui.select(select_table, {
    prompt = opts.select_prompt,
  }, function(pod, idx)
    if pod then
      opts.fun(pod)
    else
      print("You cancelled")
    end
  end)
end

function ExecuteFunctionFromInput(opts)
  vim.ui.input({
    prompt = opts.prompt,
  }, function(pod, idx)
    if pod then
      opts.fun(pod)
    else
      print("You cancelled")
    end
  end)
end

function clear_contexts()
  vim.cmd("!kubie ctx __None__")
  require("functions.tokyonight-colors").UpdateColorSchemeAndTerminal()
end

function check_k8s_context(fun)
  if GetK8sContext() == "__None__" then
    vim.notify("__None__ context, command cannot be executed", "error")
    return
  end

  fun()
end

function GetK8sContext()
  return vim.fn.system('echo -n "$(kubie info ctx)"')
end

function ExecuteK8sFunctionFromSelect(opts)
  check_k8s_context(function()
    ExecuteFunctionFromSelect(opts)
  end)
end

function ExecuteK8sFunctionFromInput(opts)
  check_k8s_context(function()
    ExecuteFunctionFromInput(opts)
  end)
end

local function get_previous_pod_logs()
  ExecuteK8sFunctionFromSelect({
    select_choices = GetPods(),
    select_prompt = "select pod",
    fun = function(pod)
      OpenOrCreateTerminal({
        instruction = "kubectl logs -p " .. pod,
        name = "prev: " .. pod,
        display_name = "kubernetes",
      })
    end,
  })
end

local function get_pod_logs()
  ExecuteK8sFunctionFromSelect({
    select_choices = GetPods(),
    select_prompt = "select pod",
    fun = function(pod)
      OpenOrCreateTerminal({
        instruction = "kubectl logs " .. pod,
        name = "logs: " .. pod,
        display_name = "kubernetes",
      })
    end,
  })
end

local function stern_query()
  ExecuteK8sFunctionFromInput({
    prompt = "stern query",
    fun = function(sternQuery)
      OpenOrCreateTerminal({
        instruction = "stern " .. sternQuery,
        name = "stern: " .. sternQuery,
        display_name = "kubernetes",
      })
    end,
  })
end

local function grep_on_stern_query()
  ExecuteK8sFunctionFromInput({
    prompt = "stern query",
    fun = function(sternQuery)
      ExecuteK8sFunctionFromInput({
        prompt = "stern query",
        fun = function(grep)
          OpenOrCreateTerminal({
            instruction = "stern " .. sternQuery .. " | grep " .. grep,
            name = "g on stern: " .. sternQuery .. " g:" .. grep,
            display_name = "kubernetes",
          })
        end,
      })
    end,
  })
end

local function grep_on_pod_log()
  ExecuteK8sFunctionFromSelect({
    select_choices = GetPods(),
    select_prompt = "select pod",
    fun = function(pod)
      ExecuteK8sFunctionFromInput({
        prompt = "grep word",
        fun = function(grep)
          OpenOrCreateTerminal({
            instruction = "kubectl logs " .. pod .. " | grep " .. grep,
            name = "g on followed: " .. pod,
            display_name = "kubernetes",
          })
        end,
      })
    end,
  })
end

local function grep_on_followed_pod()
  ExecuteK8sFunctionFromSelect({
    select_choices = GetPods(),
    select_prompt = "select pod",
    fun = function(pod)
      ExecuteK8sFunctionFromInput({
        prompt = "grep word",
        fun = function(grep)
          OpenOrCreateTerminal({
            instruction = "kubectl logs -f " .. pod .. " | grep " .. grep,
            name = "g on log: " .. pod,
            display_name = "kubernetes",
          })
        end,
      })
    end,
  })
end

-- TODO: kill all terminals which are exited
local function clean_terminals()
  local terms_table = require("toggleterm.terminal").get_all(true)
  for _, term in pairs(terms_table) do
    if term.display_name == "kubernetes" then
      vim.notify("killing kubernetes terminal: " .. term.name, "warning")
      term:shutdown()
    end
    if term.display_name == "k9s" then
      local isOpen = term:is_open()
      term:shutdown()
      term = OpenOrCreateTerminal({ instruction = "k9s --logoless", name = "k9s", direction = "float" })
      if isOpen == false then
        term:toggle()
      end
    end
  end
end

local function follow_logs()
  ExecuteK8sFunctionFromSelect({
    select_choices = GetPods(),
    select_prompt = "select pod",
    fun = function(pod)
      OpenOrCreateTerminal({
        instruction = "kubectl logs -f " .. pod,
        name = "follow: " .. pod,
        display_name = "kubernetes",
      })
    end,
  })
end

local function change_namespace()
  ExecuteK8sFunctionFromSelect({
    -- select_choices = vim.fn.system('echo -n $(kubectl get namespace --no-headers  -o custom-columns=":metadata.name")'),
    select_choices = vim.fn.system('echo -n $(kubectl get namespace --no-headers  -o custom-columns=":metadata.name")'),
    select_prompt = "select namespace",
    fun = function(ns)
      vim.cmd("!kubectl config set-context --current --namespace " .. ns)
      require("functions.tokyonight-colors").UpdateColorSchemeAndTerminal()
    end,
  })
end
-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
--   pattern = { "*" },
--   callback = require("functions.winbar").Redraw,
-- })

return {
  {
    "rottencandy/vimkubectl",
    dependencies = {
      -- which key integration
      {
        "folke/which-key.nvim",
        opts = function(_, opts)
          if require("lazyvim.util").has("noice.nvim") then
            opts.spec["<leader>k"] = { name = "+kubernetes" }
            opts.spec["<leader>kg"] = { name = "+get" }
            opts.spec["<leader>kl"] = { name = "+logs" }
            opts.spec["<leader>klg"] = { name = "+grep" }
            opts.spec["<leader>kc"] = { name = "+contexts" }
          end
        end,
      },
    },
    lazy = false,
    keys = {
      {
        "<leader>ks",
        function()
          local task = require("overseer").new_task({
            strategy = {
              "toggleterm",
              use_shell = false,
              direction = "horizontal",
              open_on_start = false,
            },
            name = "Skaffold",
            cmd = "skaffold dev",
            cwd = LazyVim.root.git(),
          })
          task:start()
        end,
        desc = "skaffold",
      },
      {
        "<leader>k9",
        function()
          OpenOrCreateTerminal({ instruction = "k9s --logoless", name = "k9s", direction = "float" })
        end,
        desc = "Open k9s",
      },
      { "<leader>kgp", "<cmd>Kget pods<cr>", desc = "Get Pods" },
      { "<leader>kgs", "<cmd>Kget svc<cr>", desc = "Get Services" },
      { "<leader>kln", get_pod_logs, desc = "Get Pod Logs" },
      { "<leader>klp", get_previous_pod_logs, desc = "Get Previous Pod Logs" },
      { "<leader>klgf", grep_on_followed_pod, desc = "Grep on pod followed log" },
      { "<leader>klgl", grep_on_pod_log, desc = "Grep on pod log" },
      { "<leader>klgs", grep_on_stern_query, desc = "Grep on Stern query" },
      { "<leader>kls", stern_query, desc = "Apply stern on query" },
      { "<leader>klf", follow_logs, desc = "Get Followed Pod Logs" },
      { "<leader>kn", change_namespace, desc = "change namespace" },
      { "<leader>kco", clear_contexts, desc = "Clear contexts" },
      {
        "<leader>kcc",
        function()
          ExecuteFunctionFromSelect({
            select_choices = vim.fn.system("echo -n $(kubie ctx)"),
            select_prompt = "selec cluster",
            fun = function(context)
              vim.cmd("!kubie ctx " .. context)
              clean_terminals()
              if GetK8sContext() ~= "__None__" then
                change_namespace()
              else
                require("functions.tokyonight-colors").UpdateColorSchemeAndTerminal()
              end
            end,
          })
        end,
        desc = "change context",
      },
    },
  },
}
