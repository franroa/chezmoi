#!/usr/bin/env python3
import subprocess
import re
import sys
import os

MAP_FILE = "/tmp/hypr_notif_map"
LETTERS = "abcdefghijklmnopqrstuvwxyz"
SELF_APP_NAME = "VimiumNotif"


def start_listening():
    current_index = 0
    with open(MAP_FILE, "w") as f:
        f.write("")

    print("Listening and modifying notifications...")

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

    for line in iter(process.stdout.readline, ""):
        line = line.strip()

        if line.startswith("method call") and "member=Notify" in line:
            in_notification = True
            string_count = 0
            app_name = ""
            app_icon = ""
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

                    # Skip our own notifications to prevent infinite loop
                    if app_name == SELF_APP_NAME:
                        in_notification = False
                        continue

                    # Skip if already has our prefix
                    if summary.startswith("[") and "]" in summary[:4]:
                        in_notification = False
                        continue

                    # Assign letter
                    letter = LETTERS[current_index % len(LETTERS)]
                    current_index += 1

                    # Create modified summary
                    mod_summary = f"[{letter.upper()}] {summary}"

                    # Save to map file
                    with open(MAP_FILE, "a") as f:
                        f.write(f"{letter}:{app_name}:{summary}\n")

                    print(f"Intercepted: {app_name} -> {mod_summary}")

                    # Send modified notification using notify-send with custom app name
                    cmd = ["notify-send", "-a", SELF_APP_NAME, mod_summary]

                    # Try to get body text
                    next_line = process.stdout.readline().strip()
                    body_match = re.search(r'string "(.*)"', next_line)
                    if body_match:
                        cmd.append(body_match.group(1))

                    subprocess.run(cmd)
                    in_notification = False


if __name__ == "__main__":
    try:
        start_listening()
    except KeyboardInterrupt:
        print("\nExiting...")
        sys.exit(0)
