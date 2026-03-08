#!/usr/bin/env python3
# Transparent GTK window to capture keypress

import sys
import os

try:
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, Gdk, GdkPixbuf
except:
    print("GTK not available")
    sys.exit(1)

NOTIF_OPENCODE = "/tmp/opencode_notifications_" + os.environ.get("USER", "froa")
NOTIF_SLACK = "/tmp/slack_notifications_" + os.environ.get("USER", "froa")
LETTER_MAP_OPENCODE = "/tmp/.opencode_letter_map"
LETTER_MAP_SLACK = "/tmp/.slack_letter_map"


class KeyCapture(Gtk.Window):
    def __init__(self):
        super().__init__(Gtk.WindowType.TOPLEVEL)

        # Transparent window
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.set_keep_above(True)
        self.stick()

        # Make transparent
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.set_app_paintable(True)
        self.connect("draw", self.on_draw)

        # Full screen but behind notification panel
        self.set_default_size(1, 1)
        self.move(0, 0)

        # Connect key press
        self.connect("key-press-event", self.on_key_press)

        # Close on escape
        self.connect("delete-event", Gtk.main_quit)

    def on_draw(self, widget, cr):
        # Fully transparent
        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.paint()

    def on_key_press(self, widget, event):
        key = Gdk.keyval_name(event.keyval)
        print(key)
        Gtk.main_quit()
        return True


def get_notification_for_letter(letter):
    if os.path.isfile(LETTER_MAP_OPENCODE):
        with open(LETTER_MAP_OPENCODE) as f:
            for line in f:
                if line.startswith(f"{letter}:"):
                    parts = line.strip().split(":")
                    if len(parts) >= 2:
                        notif_id = parts[1].split("|")[0]
                        if os.path.isfile(f"{NOTIF_OPENCODE}/{notif_id}.notif"):
                            with open(f"{NOTIF_OPENCODE}/{notif_id}.notif") as nf:
                                content = nf.read().strip()
                            return ("opencode", notif_id, letter, content)

    if os.path.isfile(LETTER_MAP_SLACK):
        with open(LETTER_MAP_SLACK) as f:
            for line in f:
                if line.startswith(f"{letter}:"):
                    parts = line.strip().split(":")
                    if len(parts) >= 2:
                        notif_id = parts[1].split("|")[0]
                        if os.path.isfile(f"{NOTIF_SLACK}/{notif_id}.notif"):
                            with open(f"{NOTIF_SLACK}/{notif_id}.notif") as nf:
                                content = nf.read().strip()
                            return ("slack", notif_id, letter, content)
    return None


def trigger_notification(app, notif_id, letter, extra):
    import subprocess

    subprocess.run(
        [
            "gdbus",
            "call",
            "--session",
            "--dest",
            "org.freedesktop.Notifications",
            "--object-path",
            "/org/freedesktop/Notifications",
            "--method",
            "org.freedesktop.Notifications.CloseNotification",
            notif_id,
        ],
        capture_output=True,
    )

    if app == "opencode":
        try:
            os.remove(f"{NOTIF_OPENCODE}/{notif_id}.notif")
        except:
            pass

        if os.path.isfile(LETTER_MAP_OPENCODE):
            with open(LETTER_MAP_OPENCODE) as f:
                lines = f.readlines()
            with open(LETTER_MAP_OPENCODE, "w") as f:
                for line in lines:
                    if not line.startswith(f"{letter}:"):
                        f.write(line)

        parts = extra.split("|")
        if len(parts) >= 3:
            subprocess.run(
                [
                    "/home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh",
                    parts[1],
                    parts[2],
                ]
            )

    elif app == "slack":
        try:
            os.remove(f"{NOTIF_SLACK}/{notif_id}.notif")
        except:
            pass

        if os.path.isfile(LETTER_MAP_SLACK):
            with open(LETTER_MAP_SLACK) as f:
                lines = f.readlines()
            with open(LETTER_MAP_SLACK, "w") as f:
                for line in lines:
                    if not line.startswith(f"{letter}:"):
                        f.write(line)

        subprocess.run(["/home/froa/.config/hypr/scripts/invoke-notification.sh"])


# Open notification panel first
os.system("astal -i hyprpanel -t notificationsmenu 2>/dev/null")
import time

time.sleep(0.1)

# Check available keys
keys = []
for letter in "abcdefghijklmnopqrstuvwxyz":
    if get_notification_for_letter(letter):
        keys.append(letter)

if not keys:
    print("No notification keys")
    sys.exit(0)

# Show hint
os.system(f'notify-send -t 1500 "Press key:" "{chr(32).join(keys)}"')

# Create window
win = KeyCapture()
win.show_all()

# Focus it
win.grab_focus()
win.grab_add()

# Try to grab keyboard
try:
    import cairo

    Gdk.pointer_ungrab(Gdk.CURRENT_TIME)
    Gdk.keyboard_grab(win.get_window(), True, Gdk.CURRENT_TIME)
except:
    pass

Gtk.main()

# Get the key that was pressed
# The key is printed to stdout from on_key_press
