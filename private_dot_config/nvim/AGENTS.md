# Neovim Configuration

This is a LazyVim-based Neovim configuration managed by chezmoi.

## Session

**Use the `neovim` session when working on this config** (`/session neovim`).
This keeps conversation history for nvim work separate from other tools.

## Structure

- `lua/config/` - Core config (keymaps, options, autocmds, lazy.lua)
- `lua/plugins/` - Plugin specs (LazyVim format)
- `lua/_old_plugins/` - Disabled/experimental plugins
- `after/` - Filetype-specific settings
- `ftdetect/` - Custom filetype detection

## Guidelines

- Follow LazyVim plugin spec conventions
- This is part of a chezmoi repo - edit here, then `chezmoi apply`
- Test changes with `:Lazy reload` or restart nvim

## Common Tasks

```lua
-- Adding a plugin: lua/plugins/my-plugin.lua
return {
  "author/plugin",
  opts = {},
}

-- Extending a LazyVim plugin
return {
  "existing/plugin",
  opts = function(_, opts)
    -- modify opts
  end,
}
```

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->