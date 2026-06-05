#!/bin/bash

DOMAIN=$1
TIER=$2
REGION=$3

# 1. Validation
if [[ -z "$DOMAIN" || -z "$TIER" || -z "$REGION" ]]; then
  echo "Usage: $0 <domain> <tier> <region>"
  exit 1
fi

# 2. Identifiers (Must match pyprland.toml class)
CLASS="k9s-${DOMAIN}-${TIER}-${REGION}"
CLUSTER="${DOMAIN}-${TIER}-${REGION}"

# 3. Tier Colors (Using hex)
BG_COLOR="#000000"
case "$TIER" in
live) BG_COLOR="#330000" ;;    # Dark Red
sandbox) BG_COLOR="#000033" ;; # Dark Blue
testing) BG_COLOR="#003300" ;; # Dark Green
esac

# 4. Background Image (Flag)
FLAG_PATH="$HOME/.config/k9s/flags/${REGION}.png"
IMG_OPTS=""
if [[ -f "$FLAG_PATH" ]]; then
  # background_tint blends the image with the background color
  IMG_OPTS="-o background_image=$FLAG_PATH -o background_image_layout=scaled -o background_tint=0.8"
fi

# 5. Launch Kitty with 50% Transparency
# background_opacity 0.5 makes it half-transparent
exec kitty \
  --class "$CLASS" \
  --title "k9s: $CLUSTER" \
  -o background="$BG_COLOR" \
  -o background_opacity=0.2 \
  -o dynamic_background_opacity=yes \
  $IMG_OPTS \
  bash -c "$HOME/.cargo/bin/kubie exec $CLUSTER default /home/linuxbrew/.linuxbrew/bin/k9s || { echo 'Connection Failed'; read; }"
