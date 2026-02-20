#!/bin/bash
# Sway cheatsheet overlay using wezterm with transparency

# Check if already open, if so close it
if pgrep -f "cheatsheet_overlay" > /dev/null; then
    pkill -f "cheatsheet_overlay"
    exit 0
fi

# Create cheatsheet content
cat << 'EOF' > /tmp/sway_cheatsheet.txt

  ════════════════════════ SWAY CHEATSHEET ════════════════════════

  ─── GENERAL ───────────────────────────────────────────────────────
  Super + Return         Open terminal (wezterm)
  Super + d              App launcher (wofi launchpad)
  Super + q              Quick settings menu
  Super + Shift+q        Kill focused window
  Ctrl + Shift+w         Kill focused window
  Super + Shift+c        Reload sway config
  Super + Shift+e        Exit sway (with confirmation)
  Super + Escape         Lock screen
  RAlt + l               Lock screen
  Super + F1             Show this cheatsheet

  ─── FOCUS NAVIGATION ──────────────────────────────────────────────
  Super + h/j/k/l        Focus left/down/up/right (vim keys)
  Super + ←/↓/↑/→        Focus left/down/up/right (arrows)
  Super + 1-0            Switch to workspace + launch app if empty
  Alt + 1-0              Switch to workspace only
  Super + Ctrl+←/→       Previous/next workspace
  Super + Ctrl+h/l       Previous/next workspace (vim keys)
  Super + a              Focus parent container
  Super + Space          Toggle focus tiling/floating

  ─── WINDOW CYCLING ────────────────────────────────────────────────
  Alt + Tab              Start cycling windows (Windows 11 style)
    Tab                  Next window (while in alt-tab mode)
    Shift+Tab            Previous window
    Escape               Cancel
  Alt + Escape           Focus previously focused window

  ─── MOVE WINDOWS ──────────────────────────────────────────────────
  Super + Shift+h/j/k/l  Move window (vim keys)
  Super + Shift+←/↓/↑/→  Move window (arrows)
  Super + Shift+1-0      Move container to workspace
  Super + Alt+←/→        Move window to prev/next workspace
  Super + Alt+h/l        Move window to prev/next workspace

  ─── LAYOUT ────────────────────────────────────────────────────────
  Super + f              Toggle fullscreen
  Alt + Return           Toggle fullscreen
  Super + Shift+Space    Toggle floating
  Super + b              Split horizontal
  Super + s              Stacking layout
  Super + w              Tabbed layout
  Super + e              Toggle split layout
  Super + Shift+p        Picture-in-Picture (480x270, bottom-right)

  ─── RESIZE MODE (Super + r) ───────────────────────────────────────
  h / ←                  Shrink width 10px
  l / →                  Grow width 10px
  k / ↑                  Shrink height 10px
  j / ↓                  Grow height 10px
  Return / Escape        Exit resize mode

  ─── SYSTEM MODE (Super + Shift+x) ─────────────────────────────────
  l                      Lock screen
  e                      Exit sway
  r                      Reload config
  Return / Escape        Exit system mode

  ─── SCRATCHPADS ───────────────────────────────────────────────────
  Super + `              Dropdown terminal (80% x 60%, top)
  Super + n              Notes (mousepad, 40% x 50%)
  Super + c              Calculator (qalc, 35% x 45%)
  Super + y              Music (Spotify, 60% x 70%)
  Super + -              Show scratchpad
  Super + Shift+-        Move to scratchpad

  ─── VIM-STYLE MARKS ───────────────────────────────────────────────
  Super + m, [a-z]       Mark current window with letter
  Super + ', [a-z]       Jump to marked window

  ─── QUICK SWAP ────────────────────────────────────────────────────
  Super + Ctrl+Return    Mark window for swap
  Super + Shift+Return   Swap with marked window

  ─── SCREENSHOTS (swappy editor) ───────────────────────────────────
  Print                  Screenshot area → edit
  Shift + Print          Screenshot full screen → edit
  Ctrl + Print           Screenshot window → edit

  ─── CLIPBOARD ─────────────────────────────────────────────────────
  Super + v              Clipboard history (cliphist + wofi)

  ─── NOTIFICATIONS (dunst) ─────────────────────────────────────────
  Super + \              Focus source + trigger action
  Super + Shift+\        Close top notification
  Super + Ctrl+\         Show last notification (history)

  ─── PRODUCTIVITY MODES ──────────────────────────────────────────────
  Super + Shift+f        Toggle Focus Mode (DND + hide bar + mute)
  Super + Shift+m        Toggle Meeting Mode (DND + mic on + inhibit idle)
  Super + Shift+n        Toggle Do Not Disturb
  Super + p              Toggle Pomodoro timer (start/pause)

  ─── LAUNCHERS ─────────────────────────────────────────────────────
  Super + Shift+b        Secrets manager (Bitwarden/KeePass/YubiKey)
  Super + Shift+w        WiFi selector
  Super + Shift+s        SSH launcher
  Super + Shift+g        Night light toggle
  Super + Shift+o        Organize windows (move to assigned workspaces)
  Super + Ctrl+t         Wofi theme switcher
  Super + Ctrl+b         Bluetooth selector

  ─── WLR-WHICH-KEY (Super+Space) ────────────────────────────────────
  <leader>p              +pomodoro (toggle/skip/reset/menu)
  <leader>u              +ui (theme/nightlight/focus/meeting/dnd)
  <leader>c              +capture (area/window/screen/record)
  <leader>o              +connect (wifi/bluetooth/ssh/vpn)
  <leader>w              +window (switch/close/move/organize)
  <leader>a              +apps (chatgpt/claude/browsers/slack/spotify)
  <leader>q              +quit (lock/suspend/reboot/poweroff)
  <leader>?              Show keymaps cheatsheet

  ─── WAYBAR MODULES (click actions) ──────────────────────────────────
  󰥔 Clock               L: Calendar  R: Clocks
  󰻠 CPU/󰍛 Memory        System stats
  󰂯 Bluetooth           L: Manager  R: Toggle power
  󰤨 Network             L: WiFi selector  R: Connection editor
  󰕾 Volume              L: Pavucontrol  Scroll: Adjust
  󰃠 Brightness          Scroll: Adjust brightness
  󰌃 Jira                Open Jira board
  󰖂 VPN                 Toggle VPN connection
  󰏔 Updates             Open system update
  󱫖 Weather             Open wttr.in
  󰔟 Pomodoro            L: Start/pause  R: Menu  Scroll: Skip/Reset
  󰏤 Meeting             Toggle meeting mode
  󰽥 Focus               Toggle focus mode
  󰂛 DND                 L: Toggle  R: Schedule notifications
  󰅶 Idle Inhibitor      Toggle screen sleep prevention
  󱂬 Organize            Organize all windows
  󰢹 SSH                 SSH launcher
  󰌋 Secrets             Secrets manager
  󰒓 Quick Settings      Settings menu
  󰐥 Power               Power menu
  ✠ Verse               Verse of the day

  ─── MEDIA KEYS ────────────────────────────────────────────────────
  XF86AudioRaiseVolume   Volume +5%
  XF86AudioLowerVolume   Volume -5%
  XF86AudioMute          Toggle mute
  XF86MonBrightnessUp    Brightness +10%
  XF86MonBrightnessDown  Brightness -10%
  Super + BrightnessUp   Next track (playerctl)
  Super + BrightnessDown Previous track (playerctl)

  ─── MOUSE ─────────────────────────────────────────────────────────
  Super + Left-drag      Move floating window
  Super + Right-drag     Resize window
  Super + Right-click    Context menu (anywhere on window)

  ─── WORKSPACE APPS ────────────────────────────────────────────────
   1 󰆍 Terminal (wezterm)     6 󰷐 Notion
   2 󰈹 Firefox                7 󱃾 K9s Sandbox
   3 󰊯 Chrome                 8 󱃾 K9s Live
   4 󰒱 Slack                  9 󰓇 Spotify
   5 󰉋 Nautilus              10 󰌋 Settings / Bitwarden

  ══════════════════════════════════════════════════════════════════
                      Press q or Escape to close
  ══════════════════════════════════════════════════════════════════

EOF

# Display using less in wezterm with custom class for window rules
wezterm start --class cheatsheet_overlay -- bash -c 'less -R /tmp/sway_cheatsheet.txt'
