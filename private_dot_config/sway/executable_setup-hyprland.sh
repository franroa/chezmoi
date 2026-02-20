#!/bin/bash
set -e

echo "=== Hyprland Installer for Ubuntu ==="
echo ""

# Clone JaKooLit's Ubuntu-Hyprland installer
echo "Cloning JaKooLit's Ubuntu-Hyprland installer (24.04 branch)..."
git clone -b 24.04 --depth=1 https://github.com/JaKooLit/Ubuntu-Hyprland.git ~/Ubuntu-Hyprland-24.04

echo ""
echo "Running installer..."
cd ~/Ubuntu-Hyprland-24.04
chmod +x install.sh
./install.sh

echo ""
echo "Backing up current waybar config..."
cd ~/.config/waybar
if [ -f config ] && [ ! -f config-sway-backup ]; then
  mv config config-sway-backup
fi

echo "Setting up Hyprland waybar config..."
cp config-hyprland config

echo ""
echo "Copying custom Hyprland config..."
cp /home/froa/.config/hypr/hyprland.conf /home/froa/.config/hypr/hyprland.conf.jakoolit-backup 2>/dev/null || true

echo ""
echo "=== Done! ==="
echo "Log out and select 'Hyprland' from GDM."
