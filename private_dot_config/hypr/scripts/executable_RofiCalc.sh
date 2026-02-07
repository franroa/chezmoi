#!/bin/bash
# Rofi Calculator - quick math from launcher
# Results are copied to clipboard automatically

rofi -show calc \
    -modi calc \
    -no-show-match \
    -no-sort \
    -calc-command "echo -n '{result}' | wl-copy"
