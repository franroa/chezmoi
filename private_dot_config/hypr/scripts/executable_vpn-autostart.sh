#!/bin/bash
# Start the froa-config OpenVPN tunnel once op-login has populated the
# 1Password secrets cache with OPEN_VPN_PASSWORD. sudo is NOPASSWD:ALL for
# this user, so no interactive prompt is needed for the openvpn invocation
# itself.
set -uo pipefail

VPN_USER="froa"
VPN_CONFIG="/etc/openvpn/froa-config.ovpn"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/op-$(id -u)}"
CACHE="$RUNTIME_DIR/op-secrets.cache.fish"

# op-login (separate exec-once) can take a while (network wait + masked
# password prompt) -- poll for the cache instead of racing it.
for _ in $(seq 1 120); do
    if [ -s "$CACHE" ] && grep -q '^set -gx OPEN_VPN_PASSWORD ' "$CACHE"; then
        break
    fi
    sleep 1
done

# fish's non-interactive startup can emit stray ANSI codes on stdout before
# the echoed value -- strip them or the password comes out corrupted.
PASSWORD=$(fish -c "source '$CACHE' 2>/dev/null; echo \$OPEN_VPN_PASSWORD" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
if [ -z "$PASSWORD" ]; then
    notify-send "VPN autostart" "OPEN_VPN_PASSWORD not available, skipping" 2>/dev/null
    exit 1
fi

AUTH_FILE=$(mktemp)
chmod 600 "$AUTH_FILE"
printf '%s\n%s\n' "$VPN_USER" "$PASSWORD" > "$AUTH_FILE"

if sudo openvpn --config "$VPN_CONFIG" --auth-user-pass "$AUTH_FILE" --daemon froa-vpn; then
    notify-send "VPN autostart" "froa-vpn connecting" 2>/dev/null
else
    notify-send "VPN autostart" "openvpn failed to start" 2>/dev/null
fi

sleep 2
rm -f "$AUTH_FILE"
