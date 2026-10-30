-- Autoformat setting
local set_autoformat = function(pattern, bool_val)
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = pattern,
    callback = function()
      vim.b.autoformat = bool_val
    end,
  })
end

set_autoformat({ "angular.html" }, false)
set_autoformat({ "typescript" }, false)
set_autoformat({ "cs" }, false)

function get_lsp_client_by_name(name)
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client.name == name then
      return client
    end
  end
  return nil
end

local ok, util = pcall(require, "lspconfig.util")
if not ok then
  vim.notify("lspconfig.util could not be loaded")
  return
end
--
-- -- https://github.com/typescript-language-server/typescript-language-server/blob/master/docs/configuration.md
local tsserver_config = {
  root_dir = util.root_pattern("package.json"),
  single_file_support = false,
  settings = {
    diagnostics = {
      ignoredCodes = { 80001 },
    },
    javascript = {
      inlayHints = {
        includeInlayEnumMemberValueHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayFunctionParameterTypeHints = true,
        --- @type 'none' | 'literals' | 'all'
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = true,
      },
    },
    typescript = {
      inlayHints = {
        includeInlayEnumMemberValueHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayFunctionParameterTypeHints = true,
        --- @type 'none' | 'literals' | 'all'
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = true,
      },
    },
  },
}

-- Specify how the border looks like
local border = {
  { "┌", "FloatBorder" },
  { "─", "FloatBorder" },
  { "┐", "FloatBorder" },
  { "│", "FloatBorder" },
  { "┘", "FloatBorder" },
  { "─", "FloatBorder" },
  { "└", "FloatBorder" },
  { "│", "FloatBorder" },
}

-- Add the border on hover and on signature help popup window
local handlers_luals = {
  ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
  ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
}

return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      -- {
      --   "<leader>ca",
      --   function()
      --     require("tiny-code-action").code_action()
      --   end,
      --   desc = "Code Actions",
      --   { noremap = true, silent = true },
      -- },
      -- {
      --   "<leader>ca",
      --   function()
      --     require("fzf-lua").lsp_code_actions({
      --
      --       -- previewer = "codeaction_native",
      --       -- preview_pager = "delta --side-by-side --width=$FZF_PREVIEW_COLUMNS",
      --       preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
      --       -- context = {
      --       --   diagnostics = get_diagnostic_at_cursor(),
      --       -- },
      --       winopts = {
      --         relative = "editor",
      --         width = 0.95,
      --         height = 0.95,
      --         row = 1,
      --         preview = { vertical = "up:80%" },
      --       },
      --     })
      --   end,
      --   "Code actions",
      --   { "n", "v" },
      -- },
      {
        "<leader>cH",
        function()
          require("lsp-format-modifications").format_modifications(
            get_lsp_client_by_name("vtsls"),
            vim.api.nvim_get_current_buf()
          )
        end,
        desc = "Format changed code",
      },
      {
        "<leader>uN",
        function()
          require("nvim-navbuddy").open()
        end,
        desc = "Navbuddy",
      },
    },
    dependencies = {
      {
        "SmiteshP/nvim-navbuddy",
        dependencies = {
          "SmiteshP/nvim-navic",
          "MunifTanjim/nui.nvim",
        },
        opts = { lsp = { auto_attach = true } },
      },
    },
    opts = function(_, opts)
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<leader>ca", require("actions-preview").code_actions }
      -- keys[#keys + 1] = { "<leader>ca", false }

      local angularls_path = require("mason-registry").get_package("angular-language-server"):get_install_path()

      local cmd = {
        "ngserver",
        "--stdio",
        "--tsProbeLocations",
        table.concat({
          angularls_path,
          vim.uv.cwd(),
        }, ","),
        "--ngProbeLocations",
        table.concat({
          angularls_path .. "/node_modules/@angular/language-server",
          vim.uv.cwd(),
        }, ","),
      }

      local angular_config = {
        cmd = cmd,
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "angular.html",
          "htmlangular",
        },
        on_new_config = function(new_config, new_root_dir)
          new_config.cmd = cmd
        end,
      }

      -- Keybinding to call the function
      opts.servers = vim.tbl_deep_extend("force", opts.servers, {
        -- html = {
        --   filetypes = {
        --     "angular.html",
        --     "html",
        --     "javascript",
        --     "javascriptreact",
        --     "javascript.jsx",
        --     "typescript",
        --     "typescriptreact",
        --     "typescript.tsx",
        --   },
        -- },
        -- -- -- Emmet TODO: checi if this is still needed
        --
        -- jsonls = {
        --   -- settings = {
        --
        --   -- json = {
        --   schemas = require("schemastore").json.schemas({
        --     select = {
        --       ".eslintrc",
        --       "package.json",
        --       "docker-compose.yml",
        --     },
        --     replace = {
        --       [".eslintrc"] = {
        --         description = "Custom JSON schema for ESLint configuration files",
        --         fileMatch = { ".eslintrc", ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml" },
        --         name = ".eslintrc",
        --         url = "https://example.com/schema/eslintrc.json",
        --       },
        --       ["docker-compose.yml"] = {
        --         description = "Custom YAML schema for Docker Compose configuration files",
        --         fileMatch = { "docker-compose.yml", "docker-compose.yaml" },
        --         name = "docker-compose.yml",
        --         url = "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json",
        --       },
        --     },
        --   }),
        --   validate = { enable = true },
        --   --   },
        --   -- },
        -- },
        --
        cucumber_language_server = {
          settings = {
            cucumber = {
              features = { "**/*.feature" },
              glue = { "**/Steps/*.cs", "**/StepDefinitions/*.cs" },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["docker-compose.yml"] = "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json",
                -- ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "/**/docker-compose*.yml",
                [require("kubernetes").yamlls_schema()] = "*.yaml",
                -- or this to only match '*.<resource>.yaml' files. ex: 'app.deployment.yaml', 'app.argocd.yaml', ...
                -- [require("kubernetes").yamlls_schema()] = require("kubernetes").yamlls_filetypes(),
              },
            },
          },
        },
        kulala_ls = {
          filetypes = {
            "http",
          },
        },
        emmet_language_server = {
          filetypes = {
            "angular.html",
            "css",
            "eruby",
            "html",
            "javascript",
            "javascriptreact",
            "less",
            "sass",
            "scss",
            "pug",
            "typescriptreact",
          },
          --   init_options = {
          --     html = {
          --       options = {
          --         -- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
          --         ["bem.enabled"] = true,
          --       },
          --     },
          --   },
        },
        -- tsserver = tsserver_config,
        -- CSS
        eslint = {
          filetypes = { "html", "angular.html" },
          -- root_dir = util.root_pattern(unpack({ ".eslintrc.yaml" })),
        },

        -- omnisharp = { -- TODO: for csharpls_extended  https://github.com/Decodetalkers/csharpls-extended-lsp.nvim
        --   handlers = {
        --     ["textDocument/definition"] = require("csharpls_extended").handler,
        --     ["textDocument/typeDefinition"] = require("csharpls_extended").handler,
        --   },
        --   cmd = { csharpls },
        --   enable_roslyn_analyzers = true,
        --   organize_imports_on_format = true,
        --   enable_import_completion = true,
        -- },
        -- cssls = {},
        gradle_ls = {
          cmd = {
            vim.env.HOME
              .. "/.local/share/nvim/vscode-gradle/gradle-language-server/build/install/gradle-language-server/bin/gradle-language-server",
          },
          root_dir = function(fname)
            return util.root_pattern(unpack({ "settings.gradle", "settings.gradle.kts" }))(fname)
              or util.root_pattern(unpack({ "build.gradle" }))(fname)
          end,
          filetypes = { "groovy", "kotlin" },
        },
        -- cssls = {
        --   filetypes = { "css", "scss", "less", "html" },
        -- },
        tailwindcss = {
          filetypes = {
            "html",
            "css",
            "scss",
            "javascript",
            "typescript",
            "javascriptreact",
            "typescriptreact",
          },
        },
        gopls = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              staticcheck = true,
              semanticTokens = true,
            },
          },
        },
        golangci_lint_ls = {},
        jsonls = {},
        lua_ls = {
          handlers = handlers_luals,
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          settings = {
            Lua = {
              hint = {
                enable = true,
              },
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },
        helm_ls = {},
        lemminx = {},
        angularls = vim.tbl_deep_extend("force", {}, angular_config),
      })
      opts["diagnostics"] = { virtual_text = false }

      -- opts["document_highlight"] = { enabled = false }
      opts["inlay_hints"] = { enabled = false }
      opts["codelens"] = { enabled = false }
      opts["automatic_installation"] = true
      opts["ensure_installed"] = {
        "helm-ls",
        "gopls",
        "dockerls",
        "bashls",
        "awk_ls",
        "jsonls",
        "emmet_language_server",
        "marksman",
        "gradle_ls",
        "lua_ls",
        "golangci_lint_ls ",
        "lemminx",
        "sqlfluff",
        "cucumber_language_server",
      }
      opts["capabilities"] = {
        textDocument = {
          completion = { completionItem = { snippetSupport = true } },
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      }
      opts["flags"] = {
        debounce_text_changes = 150,
      }
      opts["setup"] = {

        eslint = function(_, opts)
          LazyVim.lsp.on_attach(function(client)
            if client.name == "eslint" then
              client.server_capabilities.documentformattingprovider = true
            elseif client.name == "tsserver" then
              client.server_capabilities.documentformattingprovider = false
            end
          end, "eslint")
        end,
        omnisharp = function(_, opts)
          LazyVim.lsp.on_attach(function(client)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.semanticTokensProvider = false -- turn off semantic tokens
          end, "omnisharp")
        end,
        -- vtsls = function(_, opts)
        --   LazyVim.lsp.on_attach(function(client, buffer)
        --     require("lsp-format-modifications").format_modifications(client, buffer)
        --   end, "vtsls")
        -- end,
      }
    end,
  },
  {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
    event = "LspAttach",
    config = function()
      require("tiny-code-action").setup()
    end,
  },
}

-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities.textDocument.completion.completionItem.snippetSupport = true
-- capabilities.textDocument.foldingRange = {
--   dynamicRegistration = false,
--   lineFoldingOnly = true,
-- }
-- M.capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities) -- for nvim-cmp
--
-- local opts = {
--   on_attach = M.on_attach,
--   capabilities = M.capabilities,
--   flags = {
--     debounce_text_changes = 150,
--   },
-- }
