#!/usr/bin/env bash
#
# K9s Live Cluster Access
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"
# Usage: k9s-live.sh <domain> <region>
#   domain: platform, technosylva
#   region: ca01, eu01, us01
#
# Example: k9s-live.sh platform eu01

set -euo pipefail

DOMAIN="${1:-}"
REGION="${2:-}"

if [[ -z "$DOMAIN" || -z "$REGION" ]]; then
    echo "Usage: k9s-live.sh <domain> <region>"
    echo "  domain: platform, technosylva"
    echo "  region: ca01, eu01, us01"
    exit 1
fi

case "$DOMAIN" in
    platform|technosylva)
        ;;
    *)
        echo "Invalid domain: $DOMAIN"
        echo "Valid domains: platform, technosylva"
        exit 1
        ;;
esac

case "$REGION" in
    ca01|eu01|us01)
        ;;
    *)
        echo "Invalid region: $REGION"
        echo "Valid regions: ca01, eu01, us01"
        exit 1
        ;;
esac

CLUSTER="${DOMAIN}-live-${REGION}"

# Set flag based on region
case "$REGION" in
    eu01) FLAG="🇪🇺" ;;
    us01) FLAG="🇺🇸" ;;
    ca01) FLAG="🇨🇦" ;;
esac

printf '\e]11;#331a1a\a'
printf '\e]2;%s %s k9s\a' "$FLAG" "$CLUSTER"
"$HOME/.cargo/bin/kubie" exec "$CLUSTER" default /home/linuxbrew/.linuxbrew/bin/k9s || { echo "Failed to connect to $CLUSTER"; read -p "Press Enter to close..."; }
