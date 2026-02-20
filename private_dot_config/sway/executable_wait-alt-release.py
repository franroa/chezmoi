#!/usr/bin/env python3
"""Wait for Alt key release by reading raw input events."""

import struct
import sys
import os
import fcntl
import time

# Keyboard device
KBD_DEV = "/dev/input/by-path/platform-i8042-serio-0-event-kbd"

# input_event struct format
EVENT_FORMAT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

# Constants
EV_KEY = 1
KEY_LEFTALT = 56
KEY_RIGHTALT = 100
KEY_RELEASE = 0
KEY_PRESS = 1


def main():
    try:
        with open(KBD_DEV, "rb") as f:
            # Set non-blocking initially to flush old events
            fd = f.fileno()
            flags = fcntl.fcntl(fd, fcntl.F_GETFL)
            fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

            # Flush any buffered events
            try:
                while True:
                    data = f.read(EVENT_SIZE)
                    if not data or len(data) < EVENT_SIZE:
                        break
            except BlockingIOError:
                pass

            # Small delay to ensure we're past the initial key events
            time.sleep(0.05)

            # Flush again after delay
            try:
                while True:
                    data = f.read(EVENT_SIZE)
                    if not data or len(data) < EVENT_SIZE:
                        break
            except BlockingIOError:
                pass

            # Set back to blocking mode
            fcntl.fcntl(fd, fcntl.F_SETFL, flags)

            # Now wait for Alt release
            alt_is_pressed = True  # Assume Alt is pressed when we start

            while True:
                data = f.read(EVENT_SIZE)
                if len(data) < EVENT_SIZE:
                    continue

                tv_sec, tv_usec, ev_type, code, value = struct.unpack(
                    EVENT_FORMAT, data
                )

                # Track Alt key state
                if ev_type == EV_KEY and code in (KEY_LEFTALT, KEY_RIGHTALT):
                    if value == KEY_PRESS:
                        alt_is_pressed = True
                    elif value == KEY_RELEASE:
                        alt_is_pressed = False
                        sys.exit(0)

    except PermissionError:
        print(f"Permission denied: {KBD_DEV}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)


if __name__ == "__main__":
    main()
