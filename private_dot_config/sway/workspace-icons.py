#!/usr/bin/env python3
"""
Dynamic workspace icons for waybar
Subscribes to sway IPC and outputs workspace info with icons based on window contents
"""

import json
import subprocess
import sys
from collections import defaultdict

# Icon mappings: app_id/class -> icon
# Priority: more specific matches first
ICON_MAP = {
    # Terminals
    "wezterm": "󰆍",
    "kitty": "󰆍",
    "alacritty": "󰆍",
    "foot": "󰆍",
    "terminator": "󰆍",
    "gnome-terminal": "󰆍",
    # Browsers
    "firefox": "󰈹",
    "librewolf": "󰈹",
    "google-chrome": "󰊯",
    "chromium": "󰊯",
    "brave-browser": "󰖟",
    "microsoft-edge": "󰇩",
    # Communication
    "slack": "󰒱",
    "discord": "󰙯",
    "telegram": "󰔁",
    "signal": "󰭹",
    "teams": "󰊻",
    "zoom": "󰍫",
    "skype": "󰒯",
    # Files
    "org.gnome.nautilus": "󰉋",
    "nautilus": "󰉋",
    "thunar": "󰉋",
    "dolphin": "󰉋",
    "pcmanfm": "󰉋",
    "nemo": "󰉋",
    # Notes/Docs
    "notion-snap-reborn": "󰈄",
    "notion": "󰈄",
    "obsidian": "󱓧",
    "logseq": "󱓧",
    "libreoffice": "󰈙",
    "org.gnome.gedit": "󰷈",
    "mousepad": "󰷈",
    "code": "󰨞",
    "code-oss": "󰨞",
    "vscodium": "󰨞",
    "sublime_text": "󰅳",
    "jetbrains": "󰬷",
    # Kubernetes
    "kubie-terminal": "󱃾",
    "kubie-sandbox-terminal": "󱃾",
    "kubie-live-terminal": "󱃾",
    "k9s": "󱃾",
    # Media
    "spotify": "󰓇",
    "vlc": "󰕼",
    "mpv": "󰐌",
    "rhythmbox": "󰎆",
    "audacity": "󰝚",
    # Graphics
    "gimp": "󰃣",
    "inkscape": "󰴽",
    "blender": "󰂫",
    # Settings/System
    "gnome-control-center": "󰒓",
    "org.gnome.settings": "󰒓",
    "pavucontrol": "󰕾",
    "nm-connection-editor": "󰖩",
    "blueman-manager": "󰂯",
    # Password managers
    "bitwarden": "󰌋",
    "keepassxc": "󰌆",
    # Other
    "steam": "󰓓",
    "lutris": "󰺵",
    "transmission": "󰄠",
    "qbittorrent": "󰄠",
    "evince": "󰈦",
    "org.gnome.evince": "󰈦",
    "zathura": "󰈦",
    "eog": "󰋩",
    "org.gnome.eog": "󰋩",
}

# Default icon for unknown apps
DEFAULT_ICON = "󰣆"

# Max icons to show per workspace
MAX_ICONS = 4


def get_icon(app_id: str, app_class: str) -> str:
    """Get icon for an app, checking app_id first, then class"""
    # Normalize to lowercase
    app_id = (app_id or "").lower()
    app_class = (app_class or "").lower()

    # Check app_id first (wayland native)
    for key, icon in ICON_MAP.items():
        if key.lower() in app_id:
            return icon

    # Check class (xwayland)
    for key, icon in ICON_MAP.items():
        if key.lower() in app_class:
            return icon

    return DEFAULT_ICON


def get_tree():
    """Get sway tree"""
    result = subprocess.run(
        ["swaymsg", "-t", "get_tree"], capture_output=True, text=True
    )
    return json.loads(result.stdout)


def get_workspaces():
    """Get workspace list"""
    result = subprocess.run(
        ["swaymsg", "-t", "get_workspaces"], capture_output=True, text=True
    )
    return json.loads(result.stdout)


def find_windows(node, windows=None):
    """Recursively find all windows in a node"""
    if windows is None:
        windows = []

    # Check if this is a window (has app_id or window_properties)
    if node.get("type") == "con" and (
        node.get("app_id") or node.get("window_properties")
    ):
        app_id = node.get("app_id", "")
        app_class = ""
        if node.get("window_properties"):
            app_class = node["window_properties"].get("class", "")
        windows.append(
            {
                "app_id": app_id,
                "class": app_class,
                "name": node.get("name", ""),
                "focused": node.get("focused", False),
            }
        )

    # Recurse into children
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        find_windows(child, windows)

    return windows


def get_workspace_windows():
    """Get windows grouped by workspace"""
    tree = get_tree()
    workspaces = {}

    def find_workspaces(node):
        if node.get("type") == "workspace" and node.get("name"):
            ws_name = node["name"]
            windows = find_windows(node)
            workspaces[ws_name] = windows

        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            find_workspaces(child)

    find_workspaces(tree)
    return workspaces


def format_workspace_icons(windows: list) -> str:
    """Format icons for a workspace's windows"""
    if not windows:
        return ""

    # Get unique icons (preserve order, dedupe)
    icons = []
    seen = set()
    for w in windows:
        icon = get_icon(w["app_id"], w["class"])
        if icon not in seen:
            icons.append(icon)
            seen.add(icon)

    # Limit icons
    if len(icons) > MAX_ICONS:
        return " ".join(icons[: MAX_ICONS - 1]) + f" +{len(icons) - MAX_ICONS + 1}"

    return " ".join(icons)


def output_workspaces():
    """Output workspace data for waybar"""
    workspace_windows = get_workspace_windows()
    workspaces = get_workspaces()

    result = []
    for ws in workspaces:
        ws_name = ws["name"]
        windows = workspace_windows.get(ws_name, [])
        icons = format_workspace_icons(windows)

        result.append(
            {
                "num": ws.get("num"),
                "name": ws_name,
                "icons": icons,
                "focused": ws.get("focused", False),
                "urgent": ws.get("urgent", False),
                "output": ws.get("output", ""),
            }
        )

    return result


def main():
    """Main loop - subscribe to events and output updates"""
    # Initial output
    workspaces = output_workspaces()
    print(json.dumps(workspaces), flush=True)

    # Subscribe to window and workspace events
    proc = subprocess.Popen(
        ["swaymsg", "-t", "subscribe", "-m", '["window", "workspace"]'],
        stdout=subprocess.PIPE,
        text=True,
    )

    try:
        if proc.stdout:
            for line in proc.stdout:
                # On any event, refresh workspace data
                workspaces = output_workspaces()
                print(json.dumps(workspaces), flush=True)
    except KeyboardInterrupt:
        proc.terminate()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "once":
        # Single output mode (for testing)
        workspaces = output_workspaces()
        for ws in workspaces:
            print(f"Workspace {ws['name']}: {ws['icons']}")
    else:
        main()
