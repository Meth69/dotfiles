#!/bin/bash
# KDE Plasma configuration
# Requires kwin-polonium to be installed (in packages/aur.txt)

echo "🪟 Configuring KDE..."

# Enable Polonium tiling script
kwriteconfig6 --file kwinrc --group Plugins --key poloniumEnabled true

# Exclude system processes + floating apps from tiling
kwriteconfig6 --file kwinrc --group "Script-polonium" --key FilterProcess \
    "krunner, yakuake, kded, polkit, plasmashell, firefox, dolphin"

# Don't force tiled windows below floating ones
kwriteconfig6 --file kwinrc --group "Script-polonium" --key KeepTiledBelow false

# Apply
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "✅ KDE configured"
