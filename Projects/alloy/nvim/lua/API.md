# Alloy Plugin API Documentation

This document provides comprehensive API documentation for the Alloy Neovim plugin v2.0.

## Core API

### Setup and Configuration

#### `require("alloy").setup(opts)`

Initialize the Alloy plugin with optional configuration.

**Parameters:**
- `opts` (table, optional): Configuration options

**Example:**
```lua
require("alloy").setup({
  debug = false,
  loki_url = "http://localhost:3100",
  keymaps = {
    diagram = {
      close_diagram = "q",
      navigate_next = "<Tab>"
    }
  }
})
```

### Visualization API

#### `require("alloy").create_pipeline_diagram()`
Create an interactive pipeline diagram for the current buffer.

#### `require("alloy").show_pipeline_numbers()`
Show numbered pipeline steps in the current buffer.

#### `require("alloy").jump_to_next_component()`
Jump cursor to the next component in the pipeline flow.

#### `require("alloy").jump_to_previous_component()`
Jump cursor to the previous component in the pipeline flow.

### Testing API

#### `require("alloy").run_test(opts)`
Run E2E test for the current Alloy configuration.

**Parameters:**
- `opts` (table, optional): Test execution options

#### `require("alloy").run_pipeline_test(opts)`
Run E2E test for a specific pipeline.

#### `require("alloy").rerun_test()`
Rerun the last executed test.

#### `require("alloy").toggle_test_log()`
Show/hide the test log window.

#### `require("alloy").toggle_test_summary()`
Show/hide the test results summary.

### Override Management API

#### `require("alloy").edit_override()`
Edit the test override file for the component under cursor.

#### `require("alloy").show_override_icons()`
Display 🧪 icons for all overridden components in current buffer.

#### `require("alloy").clear_override_icons()`
Remove override icons from the current buffer.

#### `require("alloy").show_diff()`
Show component diff popup for the current buffer.

## Core Modules API

### Parser Module (`core.parser`)

#### `get_parsed_pipeline_data(bufnr)`
Parse Alloy configuration with intelligent caching.

**Parameters:**
- `bufnr` (number): Buffer number to parse

**Returns:**
- `components` (table): Map of component definitions
- `all_chains_by_key` (table): Pipeline dependency chains  
- `start_nodes` (table): Entry points of the pipeline

**Example:**
```lua
local parser = require("core.parser")
local components, chains, starts = parser.get_parsed_pipeline_data(0)
```

### Utilities Module (`core.utils`)

#### `validate_buffer(bufnr)`
Check if a buffer number is valid.

**Parameters:**
- `bufnr` (number): Buffer number to validate

**Returns:**
- `boolean`: True if buffer is valid

#### `validate_window(win_id)`  
Check if a window ID is valid.

**Parameters:**
- `win_id` (number): Window ID to validate

**Returns:**
- `boolean`: True if window is valid

#### `get_cursor_component(bufnr, components)`
Get the component definition under the cursor.

**Parameters:**
- `bufnr` (number): Buffer number
- `components` (table): Components map from parser

**Returns:**
- `key` (string|nil): Component key
- `data` (table|nil): Component data

#### `safe_call(fn, default)`
Execute function with error handling.

**Parameters:**
- `fn` (function): Function to execute
- `default` (any): Default return value on error

**Returns:**
- Result of `fn()` or `default` on error

#### `memoize(fn)`
Create a memoized version of a function.

**Parameters:**
- `fn` (function): Function to memoize

**Returns:**
- `function`: Memoized version with caching

#### `debounce(fn, delay)`
Create a debounced version of a function.

**Parameters:**
- `fn` (function): Function to debounce
- `delay` (number): Delay in milliseconds

**Returns:**
- `function`: Debounced version

#### `create_simple_popup(content, title, opts)`
Create a simple popup window.

**Parameters:**
- `content` (table): Lines of content
- `title` (string): Popup title
- `opts` (table, optional): Additional options

**Returns:**
- `win_id` (number): Window ID
- `buf_id` (number): Buffer ID

### Configuration Module (`alloy._core.configuration`)

#### `get(key)`
Get a top-level configuration value.

**Parameters:**
- `key` (string): Configuration key

**Returns:**
- `any`: Configuration value

#### `get_nested(key_path)`
Get a nested configuration value using dot notation.

**Parameters:**
- `key_path` (string): Dot-separated key path (e.g., "keymaps.diagram.close")

**Returns:**
- `any`: Configuration value or nil if not found

#### `is_enabled(feature)`
Check if a feature is enabled.

**Parameters:**
- `feature` (string): Feature name

**Returns:**
- `boolean`: True if feature is enabled

**Example:**
```lua
local config = require("alloy._core.configuration")
local debug = config.get("debug")
local close_key = config.get_nested("keymaps.diagram.close_diagram")
local loki_enabled = config.is_enabled("manage_loki")
```

## UI Modules API

### Popup Module (`ui.popup`)

#### `create_popup(content, opts)`
Create a customizable popup window.

**Parameters:**
- `content` (table): Lines of content to display
- `opts` (table): Popup configuration options
  - `title` (string): Window title
  - `border` (string): Border style
  - `filetype` (string): Buffer filetype
  - `keymaps` (table): Custom keymaps

**Returns:**
- `win_id` (number): Window ID
- `buf_id` (number): Buffer ID

#### `create_styled_popup(buf, title, width, height, opts)`
Create a popup with predefined styling.

#### `create_selection_popup(items, opts, on_confirm)`
Create a selection popup with navigation.

**Parameters:**
- `items` (table): Items to choose from
- `opts` (table): Options including parent window
- `on_confirm` (function): Callback when item is selected

## Integration State API

### `core.utils`

#### `notify_debug(message)`
Log debug message if debug mode is enabled.

#### `notify_debug_chunks(chunks)`
Log formatted debug message chunks.

## Feature Modules API

### Visualizer (`features.vertical.)

The visualizer module provides all diagram-related functionality. Functions
include component navigation, diagram creation, override management, and
cursor synchronization between diagrams and source code.

### Testing (`features.testing`)

The testing module handles E2E test execution, log management, result 
summarization, and override content management for component testing.

## Plugin Architecture

The plugin follows a modular architecture:

```
lua/
├── alloy/                 # Main plugin module
├── core/                  # Core parsing and utilities
├── features/              # Feature implementations
│   ├── visualizer/        # Diagram and navigation features
│   └── testing/           # Test execution and management
├── ui/                    # Reusable UI components
└── plugin/                # Command definitions and setup
```

## Error Handling

The plugin includes comprehensive error handling:

- All buffer and window operations are validated
- Parser functions handle malformed configurations gracefully
- Configuration errors are reported through health checks
- Debug logging provides detailed execution information

## Performance Considerations

- **Intelligent Caching**: Parser only re-processes when structure changes
- **Lazy Loading**: Modules are loaded on-demand
- **Memoization**: Expensive operations are cached
- **Debouncing**: Rapid successive calls are optimized

## Migration from v1.x

Version 2.0 maintains backward compatibility while providing improved APIs:

- All existing commands and keymaps continue to work
- New factory-based command system is more maintainable
- Modular parser provides better performance and testability
- Enhanced configuration system with type safety

For new development, prefer the v2.0 APIs documented above.
