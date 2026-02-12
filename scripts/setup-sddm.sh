#!/bin/bash
# Setup SDDM: Breeze theme + optional multi-monitor fix for desktop

set -e

HARDWARE_PROFILE="${1:-}"

echo "🖥️  Configuring SDDM..."

# Set Breeze theme (both machines)
sudo mkdir -p /etc/sddm.conf.d
echo '[Theme]
Current=breeze' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
echo "✅ SDDM theme set to Breeze"

# Desktop: disable secondary HDMI monitor on login screen
if [ "$HARDWARE_PROFILE" = "desktop" ]; then
    cat <<'XSETUP' | sudo tee /usr/share/sddm/scripts/Xsetup > /dev/null
#!/bin/sh
# Xsetup - run as root before the login dialog appears

xrandr --output HDMI-A-1 --off
XSETUP
    sudo chmod +x /usr/share/sddm/scripts/Xsetup
    echo "✅ SDDM will disable HDMI-A-1 on login screen"
fi
