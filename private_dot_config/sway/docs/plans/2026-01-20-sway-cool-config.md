# Sway Cool Config Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan.

**Goal:** Create a really cool sway config with advanced keybindings, visual themes, enhanced status bar, and startup automation.

**Architecture:** Modular config structure building on existing setup, integrating waybar, rofi, custom scripts for enhanced productivity and aesthetics while maintaining sway's lightweight nature.

**Tech Stack:** Sway, Waybar, Rofi, Bash scripts, swaybg for wallpapers.

### Task 1: Install Required Dependencies

**Files:**
- None (system packages)

**Step 1: Install waybar, rofi, and other tools**

Run: `sudo apt update && sudo apt install waybar rofi swaybg swaylock swayidle jq curl imagemagick` (adapt for your distro)
Expected: Packages installed without errors.

**Step 2: Verify installations**

Run: `waybar --version && rofi -version`
Expected: Version outputs confirming tools are available.

**Step 3: Create backup of current config**

Run: `cp ~/.config/sway/config ~/.config/sway/config.backup`
Expected: Backup file created.

### Task 2: Update Variables and Inputs

**Files:**
- Modify: `/home/froa/.config/sway/config` (lines 10-22, add new variables)

**Step 1: Add new variables for launcher and scripts**

Add after existing variables:
```
set $launcher rofi -show drun -theme ~/.config/rofi/theme.rasi
set $wallpaper ~/Pictures/wallpaper.jpg
set $lock swaylock -f -c 000000
```

**Step 2: Reload config to check syntax**

Run: `swaymsg reload`
Expected: No errors in logs.

**Step 3: Verify variables work**

Run: `swaymsg -t get_binding_state` (check if reload succeeds)

### Task 3: Enhance Keybindings

**Files:**
- Modify: `/home/froa/.config/sway/config` (lines 63-199, expand keybindings)

**Step 1: Update launcher binding**

Change: `bindsym $mod+d exec $menu` to `bindsym $mod+d exec $launcher`

**Step 2: Add productivity shortcuts**

Add after existing basics:
```
# Screenshot
bindsym Print exec grimshot save area ~/Pictures/$(date +%Y%m%d_%H%M%S).png

# Volume controls
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness
bindsym XF86MonBrightnessUp exec brightnessctl set +10%
bindsym XF86MonBrightnessDown exec brightnessctl set 10%-
```

**Step 3: Add custom modes**

Add after resize mode:
```
mode "system" {
    bindsym l exec $lock
    bindsym e exec swaymsg exit
    bindsym r exec swaymsg reload
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+Shift+x mode "system"
```

**Step 4: Reload and test keybindings**

Run: `swaymsg reload`
Expected: No syntax errors.

### Task 4: Configure Visual Theme

**Files:**
- Modify: `/home/froa/.config/sway/config` (add after output config)
- Create: `~/.config/sway/colors` (optional theme file)

**Step 1: Set wallpaper and colors**

Add after output config:
```
output * bg $wallpaper fill

# Theme variables
set $bg-color #282828
set $fg-color #ebdbb2
set $accent #fb4934

# Window borders and gaps
default_border pixel 2
default_floating_border pixel 2
gaps inner 5
gaps outer 0

# Colors
client.focused $accent $accent $fg-color $accent $accent
client.unfocused $bg-color $bg-color $fg-color $bg-color $bg-color
client.focused_inactive $bg-color $bg-color $fg-color $bg-color $bg-color
```

**Step 2: Create rofi theme**

Create: `~/.config/rofi/theme.rasi`
```
* {
    bg: #282828;
    fg: #ebdbb2;
    accent: #fb4934;
}
```

**Step 3: Reload and verify visuals**

Run: `swaymsg reload`
Expected: Borders and gaps applied.

### Task 5: Set Up Waybar

**Files:**
- Modify: `/home/froa/.config/sway/config` (replace bar section)
- Create: `~/.config/waybar/config` and `~/.config/waybar/style.css`

**Step 1: Replace bar section**

Replace the bar { ... } with:
```
exec waybar
```

**Step 2: Create waybar config**

Create: `~/.config/waybar/config`
```
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}: {icon}",
        "format-icons": {
            "1": "TERM",
            "2": "WEB",
            "3": "CHAT"
        }
    },
    "clock": {
        "format": "{:%Y-%m-%d %H:%M}",
        "tooltip-format": "{:%Y-%m-%d | %H:%M}"
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-icons": ["🔇", "🔈", "🔉", "🔊"]
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} 🌐",
        "format-disconnected": "Disconnected ⚠"
    },
    "cpu": {
        "format": "{usage}% "
    },
    "memory": {
        "format": "{}% "
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    }
}
```

**Step 3: Create waybar style**

Create: `~/.config/waybar/style.css`
```
* {
    font-family: "JetBrains Mono", monospace;
    font-size: 13px;
}

window#waybar {
    background-color: #282828;
    color: #ebdbb2;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ebdbb2;
}

#workspaces button.focused {
    background-color: #fb4934;
    color: #282828;
}
```

**Step 4: Reload sway**

Run: `swaymsg reload`
Expected: Waybar appears with modules.

### Task 6: Add Startup Scripts and Rules

**Files:**
- Modify: `/home/froa/.config/sway/config` (add exec commands and rules)

**Step 1: Add startup applications**

Add after include lines:
```
exec swaybg -i $wallpaper -m fill
exec waybar
exec nm-applet
exec blueman-applet
```

**Step 2: Enhance window rules**

Add after existing assigns:
```
for_window [title="Picture-in-Picture"] floating enable
for_window [app_id="pavucontrol"] floating enable
for_window [class="firefox"] inhibit_idle fullscreen
```

**Step 3: Add idle and lock**

Add idle configuration:
```
exec swayidle -w \
    timeout 300 '$lock' \
    timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep '$lock'
```

**Step 4: Reload and test**

Run: `swaymsg reload`
Expected: Apps launch, rules apply.

### Task 7: Final Testing and Verification

**Files:**
- `/home/froa/.config/sway/config`

**Step 1: Full reload**

Run: `swaymsg reload`

**Step 2: Test keybindings**

Try: Mod+d (launcher), Mod+Shift+x (system mode), Print (screenshot)
Expected: Functions work.

**Step 3: Check visuals and bar**

Verify: Colors, gaps, waybar modules display correctly.

**Step 4: Test startup**

Restart sway or logout/login.
Expected: Wallpaper, waybar, applets start automatically.

**Step 5: Restore if issues**

If broken: `cp ~/.config/sway/config.backup ~/.config/sway/config && swaymsg reload`</content>
<parameter name="filePath">docs/plans/2026-01-20-sway-cool-config.md