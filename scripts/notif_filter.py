#!/usr/bin/env python3
import subprocess
import re
import sys
import os
import time

MAP_FILE = "/tmp/hypr_notif_map"
LETTERS = "abcdefghijklmnopqrstuvwxyz"
SELF_APP_NAME = "VimiumNotif"
TARGET_APP = "slack"


def start_listening():
    current_index = 0
    with open(MAP_FILE, "w") as f:
        f.write("")

    print("Listening for Slack notifications (filter mode)...")

    process = subprocess.Popen(
        ["dbus-monitor", "interface='org.freedesktop.Notifications',member='Notify'"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
    )

    in_notification = False
    string_count = 0
    app_name = ""
    app_icon = ""
    summary = ""
    body = ""

    while True:
        line = process.stdout.readline()
        if not line:
            break
        line = line.strip()

        if line.startswith("method call") and "member=Notify" in line:
            in_notification = True
            string_count = 0
            app_name = ""
            app_icon = ""
            summary = ""
            body = ""
            continue

        if in_notification:
            match = re.search(r'string "(.*)"', line)
            if match:
                string_count += 1
                content = match.group(1)

                if string_count == 1:
                    app_name = content
                elif string_count == 2:
                    app_icon = content
                elif string_count == 3:
                    summary = content
                elif string_count == 4:
                    body = content

                if string_count >= 4:
                    in_notification = False

                    if app_name == SELF_APP_NAME:
                        continue

                    is_target = TARGET_APP.lower() in app_name.lower()

                    if not is_target:
                        continue

                    letter = LETTERS[current_index % len(LETTERS)]
                    current_index += 1
                    mod_summary = f"[{letter.upper()}] {summary}"

                    with open(MAP_FILE, "a") as f:
                        f.write(f"{letter}:{app_name}:{summary}\n")

                    time.sleep(0.2)

                    cmd = [
                        "notify-send",
                        "-u",
                        "normal",
                        "-t",
                        "5000",
                        "-a",
                        SELF_APP_NAME,
                    ]
                    if app_icon:
                        cmd.extend(["-i", app_icon])
                    cmd.append(mod_summary)
                    if body:
                        cmd.append(body)

                    subprocess.run(cmd)


if __name__ == "__main__":
    try:
        start_listening()
    except KeyboardInterrupt:
        print("\nExiting...")
        sys.exit(0)
