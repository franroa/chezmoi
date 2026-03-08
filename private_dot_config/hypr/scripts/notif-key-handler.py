#!/usr/bin/env python3
# Notification key handler - shows popup and captures keypress
# Like wlr-which-key but for notifications

import os
import sys
import subprocess
import json
import time
import signal

NOTIF_OPENCODE = "/tmp/opencode_notifications_" + os.environ.get("USER", "froa")
NOTIF_SLACK = "/tmp/slack_notifications_" + os.environ.get("USER", "froa")
LETTER_MAP_OPENCODE = "/tmp/.opencode_letter_map"
LETTER_MAP_SLACK = "/tmp/.slack_letter_map"


def get_notifications():
    notifications = []

    # OpenCode
    if os.path.isdir(NOTIF_OPENCODE):
        for f in os.listdir(NOTIF_OPENCODE):
            if f.endswith(".notif"):
                notif_id = f.replace(".notif", "")
                letter = ""
                if os.path.isfile(LETTER_MAP_OPENCODE):
                    with open(LETTER_MAP_OPENCODE) as lm:
                        for line in lm:
                            if f":{notif_id}|" in line:
                                letter = line.split(":")[0]
                                break
                if letter:
                    with open(os.path.join(NOTIF_OPENCODE, f)) as nf:
                        content = nf.read().strip()
                    notifications.append(("opencode", notif_id, letter, content))

    # Slack
    if os.path.isdir(NOTIF_SLACK):
        for f in os.listdir(NOTIF_SLACK):
            if f.endswith(".notif"):
                notif_id = f.replace(".notif", "")
                letter = ""
                if os.path.isfile(LETTER_MAP_SLACK):
                    with open(LETTER_MAP_SLACK) as lm:
                        for line in lm:
                            if f":{notif_id}|" in line:
                                letter = line.split(":")[0]
                                break
                if letter:
                    with open(os.path.join(NOTIF_SLACK, f)) as nf:
                        content = nf.read().strip()
                    notifications.append(("slack", notif_id, letter, content))

    return notifications


def trigger_notification(app, notif_id, letter, extra):
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

    # Remove from tracker
    if app == "opencode":
        try:
            os.remove(f"{NOTIF_OPENCODE}/{notif_id}.notif")
        except:
            pass
        if os.path.isfile(LETTER_MAP_OPENCODE):
            with open(LETTER_MAP_OPENCODE) as lm:
                lines = lm.readlines()
            with open(LETTER_MAP_OPENCODE, "w") as lm:
                for line in lines:
                    if not line.startswith(f"{letter}:"):
                        lm.write(line)

        # Parse extra (cwd|session)
        parts = extra.split("|")
        if len(parts) >= 2:
            cwd, session = parts[0], parts[1]
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
            with open(LETTER_MAP_SLACK) as lm:
                lines = lm.readlines()
            with open(LETTER_MAP_SLACK, "w") as lm:
                for line in lines:
                    if not line.startswith(f"{letter}:"):
                        lm.write(line)
        subprocess.run(["/home/froa/.config/hypr/scripts/invoke-notification.sh"])


def main():
    notifications = get_notifications()

    if not notifications:
        print("No notifications with letter shortcuts")
        sys.exit(1)

    # Build popup content
    lines = []
    for app, notif_id, letter, extra in notifications:
        if app == "opencode":
            content = extra.split("|")[0] if "|" in extra else extra
            icon = "🤖"
        else:
            content = extra
            icon = "💬"
        lines.append(f"[{letter}] {icon} {content}")

    # Use wofi in popup mode to capture key
    # wofi --show allows creating a popup that captures input
    popup = subprocess.Popen(
        [
            "wofi",
            "--show",
            "dmenu",
            "-i",
            "--prompt",
            "Press key:",
            "--cache",
            "/dev/null",
            "-k",
            "/dev/null",
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    # Show notifications as options
    stdout, _ = popup.communicate(input="\n".join(lines) + "\n")
    choice = stdout.strip()

    if not choice:
        sys.exit(0)

    # Extract letter from choice like [a] text
    if choice.startswith("["):
        letter = choice[1:].split("]")[0]
    else:
        sys.exit(1)

    # Find and trigger
    for app, notif_id, l, extra in notifications:
        if l == letter:
            trigger_notification(app, notif_id, letter, extra)
            break


if __name__ == "__main__":
    main()
