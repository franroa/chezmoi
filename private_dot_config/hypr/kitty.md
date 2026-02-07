# Kitty Configuration for Hyprland

## Kitty Config (`~/.config/kitty/kitty.conf`)

```conf
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #

# you can choose themes from $HOME/.config/kitty/kitty-themes/
include ./kitty-themes/00-Default.conf

# Font settings
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size 13.0

# Transparency and background
background_opacity 0.88
dynamic_background_opacity yes
confirm_os_window_close 0

# Cursor styling
cursor_shape beam
cursor_beam_thickness 2.0
cursor_blink_interval 0.5
cursor_trail 3
cursor_trail_decay 0.1 0.3

# Window padding and margins
window_padding_width 12 16
window_margin_width 0
single_window_margin_width -1

# Window styling
hide_window_decorations yes
window_border_width 0pt
draw_minimal_borders yes

# Tab bar styling
tab_bar_edge top
tab_bar_style powerline
tab_powerline_style slanted
tab_bar_margin_width 8
tab_bar_margin_height 6 6
active_tab_font_style bold
inactive_tab_font_style normal

# Scrollback
scrollback_lines 10000
scrollback_pager_history_size 10
wheel_scroll_min_lines 1
wheel_scroll_multiplier 3.0

# Bell
enable_audio_bell no
visual_bell_duration 0.0

# Selection
selection_foreground none
selection_background none
copy_on_select clipboard

# URL handling
url_style curly
open_url_with default
detect_urls yes

# Performance
sync_to_monitor yes
repaint_delay 10
input_delay 3

# Colors - Modern dark theme
foreground #c0caf5
background #1a1b26
cursor #c0caf5
cursor_text_color #1a1b26

# Selection colors
selection_foreground #c0caf5
selection_background #33467c

# Tab colors
active_tab_foreground   #1a1b26
active_tab_background   #7aa2f7
inactive_tab_foreground #a9b1d6
inactive_tab_background #24283b

# URL color
url_color #73daca

# change to x11 or wayland or leave auto
linux_display_server auto

# Set fish as default shell
shell fish
```

## Hyprland Integration

### Default Terminal
From `UserConfigs/01-UserDefaults.conf`:
```conf
$term = kitty
```

### Window Rules
From `configs/WindowRules.conf`:
```conf
windowrule = match:class ^(Alacritty|kitty|kitty-dropterm)$, tag +terminal
```

### Window Swallowing
From `configs/SystemSettings.conf`:
```conf
swallow_regex = ^(kitty)$
```

### Startup
From `configs/Startup_Apps.conf`:
```conf
exec-once = $HOME/.config/hypr/scripts/Dropterminal.sh kitty &
```

### Pyprland Scratchpads
From `pyprland.toml`:
```toml
[scratchpads.term]
command = "kitty --class=scratchpad"

[scratchpads.btop]
command = "kitty --class=btop-scratchpad btop"

[scratchpads.opencode_hypr]
command = "kitty --class=opencode-hypr --directory=/home/froa/.config/hypr -e opencode --port"

[scratchpads.opencode_nvim]
command = "kitty --class=opencode-nvim --directory=/home/froa/.config/nvim -e opencode --port"

[scratchpads.opencode_cwd]
command = "kitty --class=opencode-cwd -e opencode --port"
```

### Theme Integration
Kitty themes are managed via `scripts/Kitty_themes.sh` and wallust integration reloads kitty with:
```bash
pkill -SIGUSR1 kitty
```
