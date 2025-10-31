# Fish Shell Which-Key Plugin

A lightweight which-key implementation for Fish shell that displays all available keybindings in an interactive menu.

## Features

- **Display Keybindings**: Shows all available keybindings in a clean, formatted menu
- **Interactive Menu**: Press any key to exit and return to your prompt
- **Prefix Support**: Framework for showing bindings filtered by prefix (expandable)
- **Clean Cleanup**: Automatically clears the menu when you press a key
- **Easy Integration**: Automatically loaded from `conf.d/`

## Installation

The plugin is already installed in:
```
~/.config/fish/conf.d/which_key.fish
```

It's automatically loaded when you start Fish shell.

## Usage

### Opening the Which-Key Menu

Press **Ctrl+W** to open the which-key menu. This will display:

```
╔════════════════════════════════════════════════════════════════════════╗
║                    FISH SHELL - KEY BINDINGS                           ║
╠════════════════════════════════════════════════════════════════════════╣
║ Prefix: (root)                                                          ║
╠════════════════════════════════════════════════════════════════════════╣
║ bind --preset '' self-insert                                           ║
║ bind --preset \e\[A up-line                                            ║
║ bind --preset \e\[B down-line                                          ║
║ ... (and more bindings)                                                ║
╠════════════════════════════════════════════════════════════════════════╣
║ Press any key to close this window                                     ║
╚════════════════════════════════════════════════════════════════════════╝
```

### Closing the Menu

Press any key to close the menu and return to your normal prompt. The display will be automatically cleaned up.

## Customization

### Change the Trigger Key

Edit the last line of `~/.config/fish/conf.d/which_key.fish`:

```fish
# Change from Ctrl+W to Ctrl+H for example:
bind \ch which_key
```

Common key combinations:
- `\cw` = Ctrl+W
- `\ch` = Ctrl+H
- `\ck` = Ctrl+K
- `\cg` = Ctrl+G

### Extend with Prefix Support

To add prefix filtering, modify the `__which_key_display` function to filter bindings based on `$__which_key_prefix`.

## How It Works

1. **Display Function** (`__which_key_display`): Renders the menu with formatted keybindings
2. **Wait Function** (`read -z -n 1`): Waits for a single keypress without echoing
3. **Cleanup Function** (`__which_key_cleanup`): Returns to the main screen buffer and refreshes the prompt
4. **Keybinding** (`bind \cw`): Triggers the which-key menu with Ctrl+W

## Files

- `~/.config/fish/conf.d/which_key.fish` - Main plugin file
- `~/.config/fish/conf.d/which-key.fish` - Legacy configuration (has corrections to broken version)

## Troubleshooting

If the plugin doesn't load:

1. Check if the file exists:
   ```fish
   ls -la ~/.config/fish/conf.d/which_key.fish
   ```

2. Reload Fish configuration:
   ```fish
   source ~/.config/fish/config.fish
   ```

3. Verify the function is loaded:
   ```fish
   functions which_key
   ```

## Future Enhancements

- Filter bindings by prefix (e.g., show only git-related bindings)
- Search functionality to find specific keybindings
- Display keybinding descriptions/hints
- Multi-level navigation (press keys to drill into categories)
