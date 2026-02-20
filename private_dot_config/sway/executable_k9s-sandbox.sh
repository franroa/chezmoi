#!/usr/bin/env fish
# Set green background for sandbox environment
set -gx fish_color_background 1a3320
printf '\e]11;#1a3320\a'
printf '\e]2;🟢 SANDBOX k9s\a'
kubie exec platform-sandbox-eu01 default k9s
