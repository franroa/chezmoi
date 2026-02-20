#!/usr/bin/env python3
"""
Alt+Tab for Sway with wofi thumbnails.
- Alt+Tab: show panel immediately, select 2nd window
- Tab: cycle thumbnails
- Release Alt: commit selection, close panel
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

STATE_FILE = Path("/tmp/sway-alttab-state.json")
THUMB_DIR = Path("/tmp/sway-alttab-thumbs")
WOFI_PID_FILE = Path("/tmp/sway-alttab-wofi.pid")
THUMB_SCALE = 0.12


def sway_cmd(cmd: str):
    subprocess.run(["swaymsg", cmd], capture_output=True)


def sway_msg(msg_type: str) -> dict:
    result = subprocess.run(["swaymsg", "-t", msg_type], capture_output=True, text=True)
    try:
        return json.loads(result.stdout)
    except:
        return {}


def get_all_windows() -> list[dict]:
    tree = sway_msg("get_tree")
    windows = []

    def traverse(node):
        if node.get("type") == "con" and node.get("pid"):
            rect = node.get("rect", {})
            windows.append(
                {
                    "id": node["id"],
                    "name": node.get("name", ""),
                    "app_id": node.get("app_id", "")
                    or node.get("window_properties", {}).get("class", ""),
                    "rect": rect,
                }
            )
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            traverse(child)

    traverse(tree)
    return windows


def get_focused_window() -> int | None:
    tree = sway_msg("get_tree")

    def traverse(node):
        if node.get("focused") and node.get("pid"):
            return node["id"]
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            result = traverse(child)
            if result:
                return result
        return None

    return traverse(tree)


def focus_window(con_id: int):
    sway_cmd(f"[con_id={con_id}] focus")


def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text())
    except:
        return {"history": [], "frozen": [], "cycle_index": 0}


def save_state(state: dict):
    STATE_FILE.write_text(json.dumps(state))


def update_history(history: list, window_id: int, all_window_ids: set) -> list:
    if window_id is None:
        return history
    history = [w for w in history if w != window_id and w in all_window_ids]
    history.insert(0, window_id)
    return history


def capture_thumbnail(window: dict) -> str | None:
    rect = window.get("rect", {})
    if not rect or rect.get("width", 0) < 10:
        return None

    wid = window["id"]
    thumb_path = THUMB_DIR / f"{wid}.png"
    x, y = rect.get("x", 0), rect.get("y", 0)
    w, h = rect.get("width", 100), rect.get("height", 100)
    geometry = f"{x},{y} {w}x{h}"

    try:
        subprocess.run(
            [
                "grim",
                "-g",
                geometry,
                "-t",
                "png",
                "-s",
                str(THUMB_SCALE),
                str(thumb_path),
            ],
            capture_output=True,
            timeout=2,
        )
        if thumb_path.exists():
            return str(thumb_path)
    except:
        pass
    return None


def capture_focused_thumbnail():
    THUMB_DIR.mkdir(parents=True, exist_ok=True)
    focused = get_focused_window()
    if not focused:
        return
    for w in get_all_windows():
        if w["id"] == focused:
            capture_thumbnail(w)
            break


def get_thumbnails(windows: list[dict]) -> dict:
    THUMB_DIR.mkdir(parents=True, exist_ok=True)
    thumbs = {}
    for w in windows:
        wid = w["id"]
        thumb_path = THUMB_DIR / f"{wid}.png"
        if thumb_path.exists():
            thumbs[str(wid)] = str(thumb_path)
        else:
            path = capture_thumbnail(w)
            if path:
                thumbs[str(wid)] = path
    return thumbs


def kill_wofi():
    try:
        if WOFI_PID_FILE.exists():
            pid = int(WOFI_PID_FILE.read_text().strip())
            try:
                os.kill(pid, 9)
            except ProcessLookupError:
                pass
            WOFI_PID_FILE.unlink(missing_ok=True)
    except:
        pass
    subprocess.run(["pkill", "-9", "-f", "alttab-wofi"], capture_output=True)


def is_wofi_running() -> bool:
    try:
        if WOFI_PID_FILE.exists():
            pid = int(WOFI_PID_FILE.read_text().strip())
            os.kill(pid, 0)
            return True
    except (ProcessLookupError, ValueError, FileNotFoundError):
        WOFI_PID_FILE.unlink(missing_ok=True)
    return False


def show_wofi(frozen: list, window_names: dict, window_thumbs: dict, cycle_index: int):
    if is_wofi_running():
        return

    kill_wofi()

    # Reorder the list so the selected item is first (wofi selects first item by default)
    # Keep track of the original order for display
    reordered = frozen[cycle_index:] + frozen[:cycle_index]

    lines = []
    for wid in reordered:
        name = window_names.get(str(wid), f"Window {wid}")
        if len(name) > 40:
            name = name[:37] + "..."
        thumb_path = window_thumbs.get(str(wid), "")
        styled_name = f'<span foreground="#e0e0e0">{name}</span>'
        if thumb_path and Path(thumb_path).exists():
            lines.append(f"img:{thumb_path}:text:{wid}|{styled_name}")
        else:
            lines.append(f"{wid}|{styled_name}")

    wofi_input = "\n".join(lines)

    proc = subprocess.Popen(
        [
            "wofi",
            "--show=dmenu",
            "--define=layer=overlay",
            "--allow-images",
            "--allow-markup",
            "--cache-file=/dev/null",
            "--prompt=",
            "--width=95%",
            "--height=90%",
            "--define=image_size=180",
            "--define=hide_search=true",
            "--define=insensitive=true",
            "--define=columns=4",
            "--location=center",
            "--style=/home/froa/.config/wofi/style.css",
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )

    try:
        if proc.stdin:
            proc.stdin.write(wofi_input.encode())
            proc.stdin.close()
    except:
        pass

    WOFI_PID_FILE.write_text(str(proc.pid))

    # Fork to watch for Alt release
    if os.fork() == 0:
        try:
            watch_alt_release_and_commit()
        except:
            pass
        os._exit(0)


def is_alt_pressed() -> bool:
    try:
        import fcntl
        import array

        EVIOCGKEY = 0x80404518
        KEY_LEFTALT = 56
        KEY_RIGHTALT = 100

        kbd = Path("/dev/input/by-path/platform-i8042-serio-0-event-kbd")
        device_path = kbd.resolve() if kbd.exists() else Path("/dev/input/event3")

        with open(device_path, "rb") as f:
            buf = array.array("B", [0] * 96)
            fcntl.ioctl(f.fileno(), EVIOCGKEY + (len(buf) << 16), buf)
            left_alt = (buf[KEY_LEFTALT // 8] >> (KEY_LEFTALT % 8)) & 1
            right_alt = (buf[KEY_RIGHTALT // 8] >> (KEY_RIGHTALT % 8)) & 1
            return bool(left_alt or right_alt)
    except:
        return False


def watch_alt_release_and_commit():
    time.sleep(0.1)

    while is_alt_pressed():
        time.sleep(0.03)

    # Alt released - focus selected window based on cycle_index
    state = load_state()
    if state.get("frozen"):
        idx = state.get("cycle_index", 0)
        if 0 <= idx < len(state["frozen"]):
            selected = state["frozen"][idx]
            focus_window(selected)
            all_windows = get_all_windows()
            all_ids = set(w["id"] for w in all_windows)
            state["history"] = update_history(state["history"], selected, all_ids)

    state["frozen"] = []
    state["cycle_index"] = 0
    state["display_pos"] = 0
    save_state(state)

    kill_wofi()
    sway_cmd('mode "default"')


def cmd_daemon():
    proc = subprocess.Popen(
        ["swaymsg", "-t", "subscribe", "-m", '["window"]'],
        stdout=subprocess.PIPE,
        text=True,
    )

    state = load_state()
    current = get_focused_window()
    if current:
        all_windows = get_all_windows()
        all_ids = set(w["id"] for w in all_windows)
        state["history"] = update_history(state["history"], current, all_ids)
        save_state(state)

    if proc.stdout is None:
        return

    for line in proc.stdout:
        try:
            event = json.loads(line)
            if event.get("change") == "focus":
                state = load_state()
                if not state.get("frozen"):
                    container = event.get("container", {})
                    if container.get("pid"):
                        all_windows = get_all_windows()
                        all_ids = set(w["id"] for w in all_windows)
                        state["history"] = update_history(
                            state["history"], container["id"], all_ids
                        )
                        save_state(state)
                        capture_focused_thumbnail()
        except:
            continue


def cmd_cycle():
    """Alt+Tab: show panel, select 2nd window."""
    if is_wofi_running():
        cmd_next()
        return

    state = load_state()
    all_windows = get_all_windows()
    all_ids = set(w["id"] for w in all_windows)

    state["history"] = [w for w in state["history"] if w in all_ids]
    for w in all_ids:
        if w not in state["history"]:
            state["history"].append(w)

    if len(state["history"]) < 2:
        save_state(state)
        return

    state["frozen"] = state["history"].copy()
    state["cycle_index"] = 1
    state["display_pos"] = (
        0  # Visual position starts at 0 (first item after reordering)
    )

    window_names = {
        str(w["id"]): w.get("name") or w.get("app_id") or f"Window {w['id']}"
        for w in all_windows
    }
    window_thumbs = get_thumbnails(all_windows)

    save_state(state)
    update_wofi_css(state["cycle_index"])
    sway_cmd('mode "alt-tab"')
    show_wofi(state["frozen"], window_names, window_thumbs, state["cycle_index"])


def update_wofi_css(selected_index: int):
    """Update wofi CSS with selection styling.

    Note: We use wofi's native selection (#entry:selected) for highlighting
    since we now use keyboard navigation (wtype) to move the selection.
    The selected_index parameter is kept for compatibility but the CSS
    relies on wofi's :selected pseudo-class.
    """
    css = """/* Wofi Alt+Tab Switcher Style - Grid Layout */

window {
    background-color: rgba(20, 20, 30, 0.95);
    border-radius: 16px;
    border: 2px solid rgba(80, 80, 100, 0.6);
}

#outer-box {
    margin: 20px;
}

#input {
    opacity: 0;
    min-height: 0;
    min-width: 0;
    padding: 0;
    margin: 0;
}

#scroll {
    margin: 10px;
}

#inner-box {
    margin: 10px;
}

#entry {
    padding: 12px;
    margin: 10px;
    border-radius: 12px;
    background-color: rgba(40, 40, 50, 0.6);
    border: 2px solid rgba(60, 60, 80, 0.4);
}

/* Highlight selected entry using wofi's native selection */
#entry:selected {
    background-color: rgba(40, 70, 120, 0.85);
    border: 3px solid rgba(80, 180, 255, 0.95);
}

#entry:selected image {
    border: 2px solid rgba(100, 180, 255, 0.9);
}

image {
    margin-bottom: 10px;
    border-radius: 8px;
    background-color: rgba(0, 0, 0, 0.5);
    padding: 4px;
    border: 2px solid rgba(60, 60, 80, 0.6);
}

#text {
    font-family: "Inter", sans-serif;
    font-size: 16px;
    font-weight: 500;
    margin-top: 5px;
    color: rgba(200, 200, 220, 0.9);
}
"""
    Path("/home/froa/.config/wofi/style.css").write_text(css)


WOFI_COLUMNS = 4


def cmd_next():
    """Tab: cycle to next thumbnail in grid (left-to-right, top-to-bottom, wrap to start)."""
    state = load_state()
    if not state.get("frozen"):
        return

    n = len(state["frozen"])
    old_index = state["cycle_index"]
    new_index = (old_index + 1) % n

    display_pos = state.get("display_pos", 0)
    new_display_pos = (display_pos + 1) % n

    current_col = display_pos % WOFI_COLUMNS
    current_row = display_pos // WOFI_COLUMNS
    total_rows = (n + WOFI_COLUMNS - 1) // WOFI_COLUMNS

    # Check if we're at the last element
    if display_pos == n - 1:
        # Wrap to first element: go up to first row, then left to first column
        for _ in range(current_row):
            subprocess.run(["wtype", "-k", "Up"], capture_output=True)
        for _ in range(current_col):
            subprocess.run(["wtype", "-k", "Left"], capture_output=True)
    elif current_col == WOFI_COLUMNS - 1:
        # At end of row, go down and back to first column
        subprocess.run(["wtype", "-k", "Down"], capture_output=True)
        for _ in range(WOFI_COLUMNS - 1):
            subprocess.run(["wtype", "-k", "Left"], capture_output=True)
    else:
        subprocess.run(["wtype", "-k", "Right"], capture_output=True)

    state["cycle_index"] = new_index
    state["display_pos"] = new_display_pos
    save_state(state)


def cmd_prev():
    """Shift+Tab: cycle to previous thumbnail in grid (right-to-left, bottom-to-top, wrap to end)."""
    state = load_state()
    if not state.get("frozen"):
        return

    n = len(state["frozen"])
    old_index = state["cycle_index"]
    new_index = (old_index - 1) % n

    display_pos = state.get("display_pos", 0)
    new_display_pos = (display_pos - 1) % n

    current_col = display_pos % WOFI_COLUMNS
    current_row = display_pos // WOFI_COLUMNS

    # Calculate last element position
    last_pos = n - 1
    last_col = last_pos % WOFI_COLUMNS
    last_row = last_pos // WOFI_COLUMNS

    # Check if we're at the first element
    if display_pos == 0:
        # Wrap to last element: go down to last row, then right to last column
        for _ in range(last_row):
            subprocess.run(["wtype", "-k", "Down"], capture_output=True)
        for _ in range(last_col):
            subprocess.run(["wtype", "-k", "Right"], capture_output=True)
    elif current_col == 0:
        # At start of row, go up and to last column
        subprocess.run(["wtype", "-k", "Up"], capture_output=True)
        for _ in range(WOFI_COLUMNS - 1):
            subprocess.run(["wtype", "-k", "Right"], capture_output=True)
    else:
        subprocess.run(["wtype", "-k", "Left"], capture_output=True)

    state["cycle_index"] = new_index
    state["display_pos"] = new_display_pos
    save_state(state)


def cmd_cancel():
    """Escape: cancel, return to original window."""
    state = load_state()

    if state.get("frozen"):
        focus_window(state["frozen"][0])

    state["frozen"] = []
    state["cycle_index"] = 0
    state["display_pos"] = 0
    save_state(state)

    kill_wofi()
    sway_cmd('mode "default"')


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]
    cmds = {
        "daemon": cmd_daemon,
        "cycle": cmd_cycle,
        "next": cmd_next,
        "prev": cmd_prev,
        "cancel": cmd_cancel,
    }

    if cmd in cmds:
        cmds[cmd]()
    else:
        print(f"Unknown: {cmd}")
        sys.exit(1)
