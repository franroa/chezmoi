-- Get the path to your lsp server project
local lsp_server_path = vim.fn.expand("/home/froa/Projects/alloy/river_lsp/server")
local lspconfig = require("lspconfig")
return {
  -- root_dir = lspconfig.util.root_pattern("alloy"),

  settings = {
    alloyLsp = {
      -- Semantic highlighting configuration
      semanticTokens = {
        enabled = false, -- Disable semantic tokens for better performance
      },

      -- Symbol navigation and search
      symbols = {
        enableFuzzySearch = true,
        enableHierarchy = true,
        maxSymbolResults = 150,
        enableRelationships = true,
        enableWorkspaceSymbols = true,
        showComponentInstances = true,
      },

      -- Performance optimization settings
      performance = {
        maxFiles = 1000,
        enableCaching = true,
        enableOptimizations = true,
        debounceDelay = 300, -- milliseconds
        maxConcurrentRequests = 10,
      },

      -- Code lens configuration
      codeLens = {
        resolveProvider = true,
        enabled = true,
        showReferenceCounts = true,
        showUsageCounts = true,
        showDocumentationLinks = true,
        showValidationStatus = true,
        refreshOnSave = true,
        enableComponentLenses = true,
        enableBlockLenses = true,
      },

      -- Document formatting configuration
      formatting = {
        enabled = true,
        insertSpaces = true, -- Convert tabs to spaces
        tabSize = 2, -- Number of spaces per tab
        addMissingCommas = true, -- Add commas to map elements
        runAlloyFmt = true, -- Run alloy fmt command
      },

      -- Completion settings
      completion = {
        enabled = true,
        enableSnippets = true,
        enableArgumentCompletion = true,
        enableBlockCompletion = true,
        enableComponentCompletion = true,
        maxCompletionItems = 50,
        enableFuzzyMatching = true,
        enableContextualSuggestions = true,
      },

      -- Hover information
      hover = {
        enabled = true,
        showDocumentation = true,
        showExamples = true,
        showTypeInformation = true,
        showUsageExamples = true,
      },

      -- Diagnostics configuration
      diagnostics = {
        enabled = true,
        enableSyntaxValidation = true,
        enableComponentValidation = true,
        enableReferenceValidation = true,
        enableRequiredBlockValidation = true,
        maxDiagnostics = 100,
        debounceDelay = 500, -- milliseconds
      },

      -- Go to definition/declaration
      navigation = {
        enableDefinition = true,
        enableDeclaration = true,
        enableImplementation = true,
        enableTypeDefinition = true,
        enableReferences = true,
        enableCallHierarchy = true,
      },

      -- Document highlighting
      highlighting = {
        enableDocumentHighlight = true,
        enableSelectionRange = true,
        enableLinkedEditing = true,
      },

      -- Inlay hints
      inlayHints = {
        enabled = true,
        showParameterNames = true,
        showTypeHints = true,
        showArgumentHints = true,
      },

      -- Signature help
      signatureHelp = {
        enabled = true,
        showParameterDocumentation = true,
        showActiveParameter = true,
      },

      -- Rename functionality
      rename = {
        enabled = true,
        enablePrepareRename = true,
        enableLinkedRename = true,
      },

      -- Code actions
      codeActions = {
        enabled = true,
        enableQuickFixes = true,
        enableRefactoring = true,
        enableExtractActions = true,
      },

      -- Folding ranges
      folding = {
        enabled = true,
        enableBlockFolding = true,
        enableComponentFolding = true,
        enableCommentFolding = true,
      },

      -- Document links
      documentLinks = {
        enabled = true,
        enableComponentLinks = true,
        enableReferenceLinks = true,
        enableDocumentationLinks = true,
      },

      -- Color provider
      colorProvider = {
        enabled = true,
        enableColorPicker = true,
      },

      -- Workspace scanning
      workspace = {
        enableScanning = true,
        scanOnStartup = true,
        scanOnFileChange = true,
        maxScanDepth = 10,
        excludePatterns = {
          "node_modules",
          ".git",
          "*.log",
          "*.tmp",
        },
        includePatterns = {
          "*.alloy",
          "*.river",
        },
      },

      -- File watching
      fileWatcher = {
        enabled = true,
        watchPatterns = {
          "**/*.alloy",
          "**/*.river",
        },
        ignorePatterns = {
          "**/node_modules/**",
          "**/.git/**",
          "**/tmp/**",
        },
      },

      -- Logging and debugging
      logging = {
        level = "info", -- "trace", "debug", "info", "warn", "error"
        enableFileLogging = false,
        enableConsoleLogging = true,
        logFilePath = nil, -- Auto-generated if enableFileLogging is true
      },

      -- Component library settings
      components = {
        enableBuiltinComponents = true,
        enableCustomComponents = true,
        componentPaths = {}, -- Additional paths to scan for components
        enableComponentValidation = true,
        enableArgumentTypeChecking = true,
      },

      -- Experimental features
      experimental = {
        enableAdvancedDiagnostics = false,
        enableTypeInference = false,
        enableSmartCompletion = false,
        enablePerformanceMetrics = false,
      },
    },
  },
  -- on_attach = function(client, bufnr)
  --   -- Keybindings
  --   local opts = { buffer = bufnr }
  --   vim.keymap.set("n", "<leader>lo", vim.lsp.buf.document_symbol, opts)
  --   vim.keymap.set("n", "<leader>lS", vim.lsp.buf.workspace_symbol, opts)
  --   vim.keymap.set("n", "<leader>ls", vim.lsp.buf.document_symbol, opts) -- Alternative
  -- end,
  filetypes = {
    -- "river",
    "alloy",
    "markdown",
    "alloy_vertical_diagram",
  },
  name = "river",
  cmd = {
    "node",
    lsp_server_path .. "/out/server.js",
    -- "npx",
    -- "ts-node",
    -- -- 1. Use the FULL, absolute path to the script
    -- "--esm"
    -- lsp_server_path .. "/src/server.ts",
    -- "--stdio",
  },
  -- 2. Set the working directory to the server's ROOT folder
  cwd = lsp_server_path,
  capabilities = vim.lsp.protocol.make_client_capabilities(),
}
