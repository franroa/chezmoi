# Pyprland Configuration Guide

## Current Configuration

Your pyprland.toml has been updated with the following plugins:
- **scratchpads**: Toggleable application windows (terminal, volume control)
- **wallpapers**: Automatic wallpaper cycling from ~/Pictures/wallpapers/
- **expose**: Overview of all windows (like macOS)
- **magnify**: Zoom focused window
- **toggle_special**: Toggle special workspace
- **system_notifier**: Desktop notifications

## Keyboard Bindings Added

All bindings use SUPER (Windows key) as $mainMod:

### Scratchpads
- `SUPER + T` - Toggle terminal scratchpad
- `SUPER + V` - Toggle volume control (pavucontrol)

### Window Management
- `SUPER + E` - Expose (show all windows)
- `SUPER + SHIFT + Z` - Magnify focused window

### Workspaces
- `SUPER + Z` - Toggle special workspace (scratchpad space)

### Wallpapers
- `SUPER + SHIFT + W` - Next wallpaper
- `SUPER + ALT + W` - Previous wallpaper

## Starting Pyprland

Add to your startup applications:
```bash
# In your hyprland.conf or autostart:
exec-once = pypr
```

## Managing Pyprland

### Commands
```bash
pypr              # Start daemon (if not running)
pypr toggle term # Show/hide terminal scratchpad
pypr toggle *     # Show/hide all scratchpads
pypr expose       # Show expose view
pypr zoom         # Toggle magnification
pypr reload       # Reload configuration
pypr exit         # Stop daemon
```

### Scratchpad Configuration

The terminal scratchpad is configured to:
- Animate from top of screen
- Size: 75% width, 60% height
- 50px margin from edges

The volume scratchpad is configured to:
- Animate from right side
- Size: 40% width, 90% height
- Only starts when first toggled (lazy)
- Hides when unfocused

## Wallpaper Configuration

Currently configured to:
- Source: ~/Pictures/wallpapers/
- Interval: 30 minutes
- Supported formats: jpg, jpeg, png, webp
- Recursive search: enabled

### Wallpaper Commands
```bash
pypr wallpaper next    # Next wallpaper
pypr wallpaper prev    # Previous wallpaper
pypr wallpaper random  # Random wallpaper
```

## Customization

### Adding More Scratchpads

Edit `~/.config/hypr/pyprland.toml`:

```toml
[scratchpads.calculator]
command = "gnome-calculator"
class = "org.gnome.Calculator"
animation = "fromBottom"
size = "30% 40%"
lazy = true

[scratchpads.files]
command = "nautilus"
class = "org.gnome.Nautilus"
animation = "fromLeft"
size = "70% 80%"
```

### Animation Types
- `fromTop` - Slides from top
- `fromBottom` - Slides from bottom
- `fromLeft` - Slides from left
- `fromRight` - Slides from right
- `null` or `""` - No animation

### Size Format
Use percentages or pixels:
- `"75% 60%"` - 75% width, 60% height
- `"800px 600px"` - Fixed pixel size
- `"800px 40%"` - Mixed (width in pixels, height in %)

## Troubleshooting

### Check if running
```bash
pgrep -a pypr
```

### View logs
```bash
# Check system logs for pypr errors
journalctl -b | grep pypr
```

### Validate configuration
```bash
pypr dumpjson  # Check if config loads correctly
```

### Common Issues

1. **Scratchpad not showing**
   - Verify window class matches exactly
   - Check with: `hyprctl clients | grep class`

2. **Wallpapers not changing**
   - Ensure wallpapers directory exists
   - Check file extensions match config
   - Verify hyprpaper is running

3. **Keybindings not working**
   - Make sure pypr daemon is running
   - Check for conflicts with existing bindings
   - Verify configuration reload: `pypr reload`

## Files Modified

- `~/.config/hypr/pyprland.toml` - Main configuration
- `~/.config/hypr/UserConfigs/UserKeybinds.conf` - Keyboard bindings

## Resources

- [Pyprland Documentation](https://hyprland-community.github.io/pyprland/)
- [Pyprland GitHub](https://github.com/hyprland-community/pyprland)
- [Hyprland Wiki](https://wiki.hyprland.org/)
