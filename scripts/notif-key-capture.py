#!/usr/bin/env python3
# Full-screen transparent key capture window for notification panel

import os
import sys
import subprocess

try:
    import gi

    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gtk, Gdk
except:
    print("GTK not available")
    sys.exit(1)

NOTIF_OPENCODE = "/tmp/opencode_notifications_" + os.environ.get("USER", "froa")
NOTIF_SLACK = "/tmp/slack_notifications_" + os.environ.get("USER", "froa")
LETTER_MAP_OPENCODE = "/tmp/.opencode_letter_map"
LETTER_MAP_SLACK = "/tmp/.slack_letter_map"


class KeyCaptureWindow(Gtk.Window):
    def __init__(self):
        super().__init__(Gtk.WindowType.TOPLEVEL)

        # Fullscreen
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_skip_taskbar_hint(True)
        self.set_keep_above(True)
        self.stick()
        self.fullscreen()

        # Make transparent
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.set_app_paintable(True)

        # Label
        self.label = Gtk.Label()
        self.label.set_markup(
            "<span foreground='white' font='20'>Press a key for notification</span>"
        )
        self.label.set_halign(Gtk.Align.CENTER)
        self.label.set_valign(Gtk.Align.CENTER)
        self.add(self.label)

        # Connect events
        self.connect("key-press-event", self.on_key_press)
        self.connect("delete-event", self.on_close)

    def on_close(self, widget, event):
        Gtk.main_quit()

    def on_key_press(self, widget, event):
        key = Gdk.keyval_name(event.keyval).lower()

        # Close on escape
        if key == "escape":
            self.close()
            return True

        # Try to trigger notification
        info = get_notification_for_letter(key)
        if info:
            trigger_notification(info)
            self.close()
            return True

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
                            return ("opencode", notif_id, content)

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
                            return ("slack", notif_id, content)
    return None


def trigger_notification(info):
    app, notif_id, content = info

    # Close notification
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
                    if not line.startswith(f"{notif_id}:"):
                        f.write(line)

        # Parse content
        parts = content.split("|")
        if len(parts) >= 3:
            cwd, session = parts[1], parts[2]
            subprocess.run(
                [
                    "/home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh",
                    cwd,
                    session,
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
                    if not line.startswith(f"{notif_id}:"):
                        f.write(line)

        subprocess.run(["/home/froa/.config/hypr/scripts/invoke-notification.sh"])


# Main
win = KeyCaptureWindow()
win.show_all()

# Try to grab focus
win.grab_focus()
try:
    Gdk.keyboard_grab(win.get_window(), True, Gdk.CURRENT_TIME)
except:
    pass

# Check available keys
keys = []
for letter in "abcdefghijklmnopqrstuvwxyz":
    if get_notification_for_letter(letter):
        keys.append(letter)

if keys:
    win.label.set_markup(
        f"<span foreground='white' font='20'>Press a key: {' '.join(keys)}\nEsc to close</span>"
    )
else:
    win.label.set_markup(
        "<span foreground='white' font='20'>No notification keys\nEsc to close</span>"
    )

Gtk.main()
