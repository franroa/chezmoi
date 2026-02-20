# AGENTS.md

This is a [chezmoi](https://www.chezmoi.io/) dotfiles repository managing system configuration files.

## Repository Structure

Chezmoi uses special naming conventions for files and directories:
- `dot_` prefix → `.` (e.g., `dot_bashrc` → `.bashrc`)
- `private_` prefix → sets file permissions to `0600`
- `exact_` prefix → removes files not managed by chezmoi in that directory
- `symlink_` prefix → creates a symlink
- `empty_` prefix → creates an empty file

**Key directories:**
- `private_dot_config/` → `~/.config/` (most application configs)
- `dot_opencode/` → `~/.opencode/` (opencode AI assistant config)
- `private_dot_local/` → `~/.local/`
- `dot_kube/` → `~/.kube/` (Kubernetes configs)

## Main Configurations

| Tool | Path | Description |
|------|------|-------------|
| Fish shell | `private_dot_config/private_fish/` | Primary shell |
| Neovim | `private_dot_config/nvim/` | LazyVim-based config |
| Hyprland | `private_dot_config/hypr/` | Wayland compositor |
| Kitty | `private_dot_config/kitty/` | Terminal emulator |
| Git | `private_dot_config/git/` | Git configuration |
| Starship | `private_dot_config/starship.toml` | Shell prompt |

## Commands

```bash
# Apply changes to home directory
chezmoi apply

# Preview changes before applying
chezmoi diff

# Add a new file to be managed
chezmoi add ~/.config/some-app/config

# Edit a managed file
chezmoi edit ~/.config/some-app/config
```

## Guidelines

- **NEVER edit files outside of this repository (`~/.local/share/chezmoi/`). All config changes must be made here.**
- **Always edit files in this chezmoi repository, not the actual home directory files**
- **After editing files, always ask the user before running `chezmoi apply` to sync changes to the home directory**
- Sensitive files should use the `private_` prefix
- Use `.chezmoiignore` to exclude files from management
- This repo targets Linux (Arch-based) with Wayland/Hyprland
