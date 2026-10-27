#!/bin/bash
# Launch Slack (native deb package with Wayland support)

exec /usr/bin/slack \
    --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer \
    --ozone-platform=wayland \
    "$@"
