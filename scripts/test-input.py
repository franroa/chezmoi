#!/usr/bin/env python3
# Read keyboard input directly from /dev/input

import os
import struct
import time

# EV_KEY = 0x01
EV_KEY = 0x01

# Open keyboard device
try:
    fd = os.open("/dev/input/event3", os.O_RDONLY | os.O_NONBLOCK)
    print("Keyboard opened")
except PermissionError:
    print("Need to be in input group or run as root")
    exit(1)

# Event format: struct input_event { timeval tv; __u16 type; __u16 code; __s32 value; }
# = lHHI
EVENT_FORMAT = "llHHI"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)

KEY_MAP = {
    30: "a",
    48: "b",
    46: "c",
    32: "d",
    18: "e",
    33: "f",
    34: "g",
    35: "h",
    23: "i",
    36: "j",
    37: "k",
    38: "l",
    50: "m",
    49: "n",
    24: "o",
    25: "p",
    16: "q",
    19: "r",
    31: "s",
    20: "t",
    22: "u",
    47: "v",
    17: "w",
    45: "x",
    21: "y",
    44: "z",
}

print("Reading keys... (press Ctrl+C to stop)")

try:
    while True:
        try:
            data = os.read(fd, EVENT_SIZE)
            if data:
                tv_sec, tv_usec, event_type, event_code, value = struct.unpack(
                    EVENT_FORMAT, data
                )
                if event_type == EV_KEY and value == 1:  # key down
                    if event_code in KEY_MAP:
                        print(f"Key: {KEY_MAP[event_code]}")
        except BlockingIOError:
            pass
        time.sleep(0.01)

except KeyboardInterrupt:
    print("\nStopped")

os.close(fd)
