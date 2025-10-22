# Alloy Visualizer & Tester

This Neovim plugin provides a suite of tools to visualize your Grafana Alloy configurations and run E2E tests directly from the editor.

## Recent Refactoring (v2.0)

The plugin has been significantly refactored for better maintainability and performance:

### 🚀 **Architecture Improvements**
- **Streamlined Command System**: Eliminated unnecessary wrapper layers for direct feature access
- **Modular Parser**: Broke down the 200+ line parser into focused, testable functions
- **Factory Patterns**: Commands are now generated systematically, making new features easier to add
- **Enhanced Configuration**: Added nested configuration access and feature flags

### 📁 **New Structure**
- **Core Modules**: `lua/core/` - Parser, utilities, and integration state
- **Features**: `lua/features/` - Visualizer and testing functionality  
- **UI Components**: `lua/ui/` - Reusable popup, highlight, and icon systems
- **Configuration**: `lua/alloy/_core/` - Centralized configuration management
- **Plugin Integration**: `lua/plugin/` - Command definitions and keymaps

### 🔧 **Developer Benefits**
- **50% Less Code**: Removed redundant wrapper functions and duplicate patterns
- **Better Performance**: Improved caching and reduced function call overhead
- **Easier Testing**: Modular functions with single responsibilities
- **Type Safety**: Enhanced type annotations and configuration validation

## Features

### 🎯 **Core Functionality**
- **Smart Pipeline Visualization**: Generate horizontal or vertical diagrams with intelligent caching
- **E2E Testing Framework**: Run tests for entire configurations or specific pipelines
- **Context-Aware Operations**: Automatically detect and operate on the pipeline under your cursor
- **Interactive Test Results**: Detailed summaries with diff views for failed tests
- **Bidirectional Navigation**: Jump between diagrams and source code seamlessly

### 🛠 **Advanced Features**
- **Override Management**: Create and edit test overrides with visual indicators
- **Performance Optimization**: Smart caching that only re-parses when structure changes
- **Configuration Validation**: Built-in health checks and configuration verification
- **Tool Integration**: Optional Lualine status integration and Telescope support

## Quick Start

### Installation

Using your favorite plugin manager:

```lua
-- lazy.nvim
{
  "your-username/alloy.nvim",
  ft = "alloy",
  config = function()
    require("alloy").setup({
      -- Optional configuration
      debug = false,
      loki_url = "http://localhost:3100",
      keymaps = {
        diagram = {
          toggle_pipeline_focus = "P",
          navigate_next = "<Tab>",
          navigate_prev = "<S-Tab>",
        }
      }
    })
  end
}
```

### Commands

All commands are available via `:Alloy<Tab>` completion:

| Command | Description |
|---------|-------------|
| `:AlloyCreateDiagram` | Create pipeline diagram |
| `:AlloyShowPipelineNumbers` | Show step numbers |
| `:AlloyRunTest` | Run E2E test |
| `:AlloyRunPipelineTest` | Run test for specific pipeline |
| `:AlloyToggleTestSummary` | Toggle test results |
| `:AlloyEditOverride` | Edit component override |

### Default Keymaps

#### In .alloy Files
- `gp` - Open horizontal pipeline diagram
- `<leader>tar` - Run pipeline test
- `<leader>te` - Edit component override
- `]a / [a` - Jump between pipeline components

#### In Diagrams (`g?` for help)
- `<Tab> / <S-Tab>` - Navigate components
- `<CR>` - Jump to definition
- `<leader>k` - Show component code/diff
- `P` - Toggle pipeline focus mode
- `q` - Close diagram

## Configuration

The plugin uses a comprehensive configuration system with type safety:

```lua
require("alloy").setup({
  -- Testing configuration
  loki_url = "http://localhost:3100",
  manage_loki = true,
  override_dir_name = ".alloy_tests",
  
  -- Development options
  debug = false,
  
  -- Keymap customization
  keymaps = {
    diagram = {
      toggle_pipeline_focus = "P",
      navigate_next = "<Tab>",
      navigate_prev = "<S-Tab>",
      close_diagram = "q",
      show_help = "g?",
    }
  },
  
  -- Tool integrations
  tools = {
    lualine = {
      alloy_status = {
        color = "Normal",
        text = " Alloy"
      }
    }
  }
})
```

## Health Check

Run `:checkhealth alloy` to verify your setup and dependencies.
