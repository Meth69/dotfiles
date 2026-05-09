#!/bin/bash
# Setup Hyprland session: GTK/Qt theming via gsettings

set -e

echo "🎨 Configuring Hyprland theming..."

# GTK theme settings (read by GTK apps in Hyprland via gsettings)
gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
echo "✅ GTK theme set (Tokyonight-Dark, Papirus-Dark, Bibata-Modern-Classic)"

echo "✅ Hyprland theming configured"
echo "   Qt theming (Kvantum/kvantum-dark) is configured via ~/.config/Kvantum/kvantum.kvconfig"
echo "   and env vars QT_QPA_PLATFORMTHEME=kvantum in hyprland.conf"

bash "$HOME/scripts/setup-firefox-wayland.sh"
