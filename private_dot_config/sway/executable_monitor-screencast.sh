#!/bin/bash
# Script to monitor for Screencast start and close events
# and disable/enable dunst notifications during screencast session

monitor-start() {
    dbus-monitor \
        --session --profile \
        "interface='org.freedesktop.portal.ScreenCast',member='Start'" \
        | while read -r line; do
            if echo $line | grep -q 'ScreenCast.*Start'; then
                dunstctl set-paused true >/dev/null
            fi
        done
}

monitor-close() {
    dbus-monitor \
        --session --profile \
        "interface='org.freedesktop.portal.Session',member='Close'" \
        | while read -r line; do
            if echo $line | grep -q 'webrtc_session.*Close'; then
                dunstctl set-paused false >/dev/null
            fi
        done
}

trap "kill 0" EXIT

monitor-start &
monitor-close
