#!/bin/bash
# Wait for Alt key release by reading raw keyboard events
# Alt_L = keycode 56, Alt_R = keycode 100
# Event type 1 = EV_KEY, value 0 = release

KBD_DEV="/dev/input/by-path/platform-i8042-serio-0-event-kbd"

# Each input_event struct is 24 bytes on 64-bit:
# struct timeval (16 bytes) + type (2 bytes) + code (2 bytes) + value (4 bytes)

# Read events until we see Alt release
while read -r -n 24 event; do
    if [ ${#event} -eq 24 ]; then
        # Extract type (bytes 16-17), code (bytes 18-19), value (bytes 20-23)
        # Using od/hexdump would be cleaner but this works
        type_val=$(echo -n "$event" | tail -c 8 | head -c 2 | od -An -tu2 | tr -d ' ')
        code_val=$(echo -n "$event" | tail -c 6 | head -c 2 | od -An -tu2 | tr -d ' ')
        value_val=$(echo -n "$event" | tail -c 4 | od -An -tu4 | tr -d ' ')
        
        # EV_KEY=1, Alt_L=56, Alt_R=100, release=0
        if [ "$type_val" = "1" ] && { [ "$code_val" = "56" ] || [ "$code_val" = "100" ]; } && [ "$value_val" = "0" ]; then
            exit 0
        fi
    fi
done < "$KBD_DEV"
