#!/usr/bin/env python3
import subprocess
import os
import glob
import sys

SLACK_NOTIF_DIR = "/tmp/slack_notifications_" + os.environ.get("USER", "froa")
OPENCODE_NOTIF_DIR = "/tmp/opencode_notifications_" + os.environ.get("USER", "froa")


def get_opencode_notifications():
    """Get OpenCode notifications from tracking directory."""
    notifications = []
    if os.path.isdir(OPENCODE_NOTIF_DIR):
        files = glob.glob(f"{OPENCODE_NOTIF_DIR}/*.notif")
        for f in files:
            notif_id = os.path.basename(f).replace(".notif", "")
            mtime = os.path.getmtime(f)
            content = ""
            try:
                with open(f, "r") as fh:
                    content = fh.read().strip()
            except:
                pass
            notifications.append(
                {"id": notif_id, "app": "OpenCode", "content": content, "mtime": mtime}
            )
    # Sort by modification time, newest first
    notifications.sort(key=lambda x: x["mtime"], reverse=True)
    return notifications


def get_slack_notifications():
    """Get Slack notifications from tracking directory."""
    notifications = []
    if os.path.isdir(SLACK_NOTIF_DIR):
        files = glob.glob(f"{SLACK_NOTIF_DIR}/*.notif")
        for f in files:
            notif_id = os.path.basename(f).replace(".notif", "")
            mtime = os.path.getmtime(f)
            content = ""
            try:
                with open(f, "r") as fh:
                    content = fh.read().strip()
            except:
                pass
            notifications.append(
                {"id": notif_id, "app": "Slack", "content": content, "mtime": mtime}
            )
    # Sort by modification time, newest first
    notifications.sort(key=lambda x: x["mtime"], reverse=True)
    return notifications


def get_slack_action_id(notif):
    """Extract the action ID to use from a Slack notification dict.
    .notif files store the action_id, but legacy files stored 'slack'."""
    content = notif.get("content", "default")
    if content in ("slack", "opencode", ""):
        return "default"
    return content


def invoke_notification(notif_id, action_id="default"):
    """Try to invoke notification via busctl EmitActionInvoked."""
    result = subprocess.run(
        [
            "busctl",
            "--user",
            "call",
            "org.freedesktop.Notifications",
            "/org/freedesktop/Notifications",
            "org.freedesktop.Notifications",
            "EmitActionInvoked",
            "us",
            str(notif_id),
            action_id,
        ],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def close_notification(notif_id):
    """Close the notification."""
    subprocess.run(
        [
            "busctl",
            "--user",
            "call",
            "org.freedesktop.Notifications",
            "/org/freedesktop/Notifications",
            "org.freedesktop.Notifications",
            "CloseNotification",
            "u",
            str(notif_id),
        ],
        capture_output=True,
    )


def invoke_opencode_action(notif_id, content=""):
    """Try to invoke notification action, then open session."""
    # Parse content (format: "cwd|session")
    cwd = ""
    session = "default"
    if content and "|" in content:
        parts = content.split("|")
        cwd = parts[0]
        session = parts[1] if len(parts) > 1 else "default"

    # First try to invoke the notification action via busctl
    if invoke_notification(notif_id):
        # Action invoked successfully, close notification
        close_notification(notif_id)
        return True

    # Fallback: open the session directly
    if cwd and session:
        subprocess.run(
            [
                "/home/froa/.config/hypr/UserScripts/aoe-scratchpad-open.sh",
                cwd,
                session,
            ],
            capture_output=True,
        )
        close_notification(notif_id)
        return True
    else:
        # Fallback: try the default opencode script
        subprocess.run(
            ["/home/froa/.config/hypr/scripts/opencode-open-latest-notification.sh"],
            capture_output=True,
        )
        return False


def hide_scratchpads():
    """Hide all pyprland scratchpads before switching to Slack."""
    subprocess.run(
        [os.path.expanduser("~/.local/bin/pypr"), "hide", "*"],
        capture_output=True,
    )


def invoke_slack():
    """Call the existing invoke script which properly handles Slack."""
    hide_scratchpads()
    result = subprocess.run(
        ["/home/froa/.config/hypr/scripts/invoke-notification.sh"],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def get_current_slack_notif_id():
    """Query hyprpanel for the current Slack notification ID."""
    try:
        # Get notification IDs
        result = subprocess.run(
            [
                "busctl",
                "--user",
                "call",
                "org.freedesktop.Notifications",
                "/org/freedesktop/Notifications",
                "org.freedesktop.Notifications",
                "NotificationIds",
            ],
            capture_output=True,
            text=True,
            timeout=5,
        )

        if result.returncode != 0:
            return None

        # Parse IDs
        ids = []
        parts = result.stdout.strip().split()
        if len(parts) > 1:
            ids = [int(x) for x in parts[1:] if x.isdigit()]

        # Find the latest Slack notification
        for nid in ids:
            result = subprocess.run(
                [
                    "busctl",
                    "--user",
                    "call",
                    "org.freedesktop.Notifications",
                    "/org/freedesktop/Notifications",
                    "org.freedesktop.Notifications",
                    "GetNotificationJson",
                    "u",
                    str(nid),
                ],
                capture_output=True,
                text=True,
                timeout=2,
            )

            output = result.stdout.strip()
            if output.startswith('s "'):
                import json

                # s[2:] is the outer JSON string literal; parse twice to get the dict
                data = json.loads(json.loads(output[2:]))
                app_name = data.get("app_name", "")
                if "slack" in app_name.lower():
                    return str(nid)

        return None
    except:
        return None


def main():
    n = 1
    if len(sys.argv) > 1:
        try:
            n = int(sys.argv[1])
        except ValueError:
            n = 1

    # Get OpenCode notifications (from letter map)
    opencode_notifs = get_opencode_notifications()

    # Get Slack notifications (from tracking dir)
    slack_notifs = get_slack_notifications()

    print(f"OpenCode notifications: {len(opencode_notifs)}")
    print(f"Slack notifications: {len(slack_notifs)}")

    # Combined list - OpenCode first (newer), then Slack
    all_notifs = opencode_notifs + [{"app": "slack", "notifs": slack_notifs}]

    # Check if we're invoking by index or by letter
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        # Check if it's a number (index) or letter
        if arg.isdigit():
            # Index-based (1, 2, 3...)
            idx = int(arg) - 1
            if idx < len(opencode_notifs):
                # OpenCode notification by index
                notif = opencode_notifs[idx]
                print(f"Invoking OpenCode notification {idx + 1}: {notif}")
                invoke_opencode_action(notif["id"], notif.get("content", ""))
                # Close notification
                close_notification(notif["id"])
                return
            else:
                # Slack notification by index
                slack_idx = idx - len(opencode_notifs)
                if slack_idx >= 0 and slack_idx < len(slack_notifs):
                    notif = slack_notifs[slack_idx]
                    print(f"Invoking Slack notification {slack_idx + 1}: {notif}")
                    hide_scratchpads()
                    if invoke_notification(notif["id"], get_slack_action_id(notif)):
                        close_notification(notif["id"])
                    else:
                        invoke_slack()
                    return
        elif arg.isalpha():
            # Letter-based (a, b, c...) or special key like "g"
            # Treat "g" as first notification, other letters try to find match
            letter = arg.lower()

            # "g" triggers first notification (as per requirement)
            if letter == "g" and opencode_notifs:
                notif = opencode_notifs[0]
                print(f"Invoking first OpenCode notification (g key): {notif}")
                invoke_opencode_action(notif["id"], notif.get("content", ""))
                close_notification(notif["id"])
                return

            # Find OpenCode notification with this letter (legacy support)
            for notif in opencode_notifs:
                if notif.get("letter", "").lower() == letter:
                    print(f"Invoking OpenCode by letter {letter}: {notif}")
                    invoke_opencode_action(notif["id"], notif.get("content", ""))
                    close_notification(notif["id"])
                    return
            # Check Slack letter map if exists
            slack_letter_map = "/tmp/.slack_letter_map"
            if os.path.isfile(slack_letter_map):
                with open(slack_letter_map, "r") as f:
                    for line in f:
                        if line.startswith(letter + ":"):
                            parts = line.strip().split(":")
                            if len(parts) >= 2:
                                info = parts[1].split("|")
                                notif_id = info[0] if info else ""
                                print(f"Invoking Slack by letter {letter}")
                                hide_scratchpads()
                                if invoke_notification(notif_id):
                                    close_notification(notif_id)
                                else:
                                    invoke_slack()
                                return

    # Default: invoke first notification
    if opencode_notifs:
        notif = opencode_notifs[0]
        print(f"Invoking first OpenCode notification: {notif}")
        invoke_opencode_action(notif["id"], notif.get("content", ""))
        close_notification(notif["id"])
    elif slack_notifs:
        notif = slack_notifs[0]
        print(f"Invoking first Slack notification: {notif}")
        hide_scratchpads()
        if invoke_notification(notif["id"], get_slack_action_id(notif)):
            close_notification(notif["id"])
        else:
            invoke_slack()
    else:
        print("No notifications found")
        invoke_slack()


if __name__ == "__main__":
    main()
