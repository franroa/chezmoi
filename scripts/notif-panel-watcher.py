#!/usr/bin/env python3
# Notification panel key grabber using GTK popup

import os
import subprocess
import sys
import time

NOTIF_OPENCODE = "/tmp/opencode_notifications_" + os.environ.get("USER", "froa")
NOTIF_SLACK = "/tmp/slack_notifications_" + os.environ.get("USER", "froa")
LETTER_MAP_OPENCODE = "/tmp/.opencode_letter_map"
LETTER_MAP_SLACK = "/tmp/.slack_letter_map"


def get_layer_visible():
    try:
        result = subprocess.run(["hyprctl", "layers"], capture_output=True, text=True)
        return "notificationsmenu" in result.stdout
    except:
        return False


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


def show_popup_and_capture():
    """Show a small GTK window to capture a key"""
    # Use wofi in capture mode
    result = subprocess.run(
        [
            "wofi",
            "--show",
            "dmenu",
            "-i",
            "--prompt",
            "Press key:",
            "-lines",
            "0",
            "-width",
            "15",
            "-k",
            "/dev/null",
        ],
        capture_output=True,
        text=True,
        input="",
    )
    key = result.stdout.strip().lower()

    if key:
        # Find matching notification
        info = get_notification_for_letter(key)
        if info:
            trigger_notification(*info)
            return True
    return False


def main():
    was_visible = False

    while True:
        visible = get_layer_visible()

        if visible and not was_visible:
            # Panel opened - start capturing
            print("Panel open - capturing key...")
            was_visible = True

            # Show hint
            subprocess.run(
                [
                    "notify-send",
                    "-t",
                    "1500",
                    "Press letter key",
                    "Notification mode active",
                ]
            )

            # Capture key
            try:
                show_popup_and_capture()
            except Exception as e:
                print(f"Error: {e}")

        elif not visible and was_visible:
            # Panel closed
            print("Panel closed")
            was_visible = False

        time.sleep(0.2)


if __name__ == "__main__":
    main()
