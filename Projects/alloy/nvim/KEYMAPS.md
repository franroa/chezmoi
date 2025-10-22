# Alloy.nvim Keymap Configuration

This document explains how the keymap system works in Alloy.nvim and how you can customize it.

## How It Works

The keymap system is centralized and context-aware, with default keybindings defined in `core/default_keymaps.lua` and organized by context:

### Keymap Contexts

1. **Global** (`GLOBAL_DEFAULTS`): Work everywhere in alloy files
   - Create diagrams, navigate components, show help, etc.

2. **Common Diagram** (`COMMON_DIAGRAM_DEFAULTS`): Work in any diagram buffer  
   - Scroll source, go to definition, run tests, edit overrides, etc.

3. **Horizontal Diagram** (`DIAGRAM_DEFAULTS`): Work only in horizontal diagrams
   - Toggle pipeline focus, navigate, close diagram, debug cursor

4. **Vertical Diagram/Outline** (`OUTLINE_DEFAULTS`): Work only in vertical diagrams
   - Sync save, filter diagram, filter by cursor, clear filter

5. **Testing** (`TESTING_DEFAULTS`): Work in testing contexts
   - Toggle test logs, run tests, setup/cleanup environments

## Default Keybindings

### Global (Available Everywhere)
- `<leader>ap` - Create Pipeline Diagram (Horizontal)
- `<leader>av` - Create Pipeline Diagram (Vertical)  
- `<leader>aj` - Jump to Next Component
- `<leader>ak` - Jump to Previous Component
- `<leader>ah` - Show Help
- `<leader>an` - Show Pipeline Numbers

### Common Diagram (Any Diagram Buffer)
- `<C-u>` - Scroll Source Up
- `<C-d>` - Scroll Source Down  
- `<CR>` - Go to Definition / Show Test Summary
- `g?` - Show Help Popup
- `<leader>r` - Run Pipeline Test from Diagram
- `<leader>o` - Edit Override File
- `<leader>s` - Show Component Code

### Horizontal Diagram Specific
- `P` - Toggle Pipeline Focus
- `<Tab>` - Navigate Next
- `<S-Tab>` - Navigate Previous
- `q` - Close Diagram Buffer
- `<leader>d` - Debug Cursor Position

### Vertical Diagram/Outline Specific  
- `<C-s>` - Sync Save Block to .alloy
- `f` - Filter Diagram
- `F` - Filter by Cursor
- `<S-f>` - Filter Current Component
- `c` - Clear Filter

### Testing Specific
- `<leader>tl` - Toggle Test Log
- `<leader>te` - Run E2E Test
- `<leader>tr` - Rerun E2E Test  
- `<leader>tp` - Run Pipeline Test
- `<leader>ts` - Toggle Summary
- `<leader>tu` - Setup Test Environment
- `<leader>tc` - Cleanup Test Environment

## Customizing Keymaps

You can customize keymaps in your Alloy configuration:

```lua
require("alloy").setup({
  keymaps = {
    -- Change a keymap
    ["create-pipeline-diagram"] = { "n", "<leader>P" },
    
    -- Disable a keymap  
    ["show-help"] = false,
    
    -- Change mode and add options
    ["go-to-definition"] = { "n", "<CR>", { noremap = true, silent = false } },
    
    -- Add custom keymaps (you'll need to register the action separately)
    ["my-custom-action"] = { "n", "<leader>ca" },
  }
})
```

## Disabling Default Keymaps

If you want to completely disable all default keymaps and define your own:

```lua
require("alloy").setup({
  use_default_keymaps = false,
  -- Your custom keymaps would go here
})
```

## File Structure

- `core/default_keymaps.lua` - Central default keymap definitions
- `alloy/_core/configuration.lua` - Configuration system that uses default keymaps
- `core/keymap_utils.lua` - Keymap registration and management utilities
- `alloy/keymaps.lua` - Global keymap registration
- `features/*/keymaps.lua` - Context-specific keymap registration

Each keymap file includes common keymaps plus context-specific ones, ensuring consistent behavior across different parts of the plugin.