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

# Desktop: keep the login screen on DisplayPort and disable connected HDMI
if [ "$HARDWARE_PROFILE" = "desktop" ]; then
    cat <<'XSETUP' | sudo tee /usr/share/sddm/scripts/Xsetup > /dev/null
#!/bin/sh
# Xsetup - run as root before the login dialog appears
#
# Keep the SDDM greeter on the main DisplayPort monitor.
# Only disable HDMI outputs that are actually connected; forcing xrandr against
# a disconnected/stale output can blank the greeter on some AMDGPU/Xorg boots.

main_output="$(xrandr --query | awk '/^DisplayPort-[0-9]+ connected/ { print $1; exit }')"

if [ -n "$main_output" ]; then
    xrandr --output "$main_output" --primary --auto

    xrandr --query | awk '/^HDMI-A-[0-9]+ connected/ { print $1 }' |
        while read -r hdmi_output; do
            xrandr --output "$hdmi_output" --off
        done
fi
XSETUP
    sudo chmod +x /usr/share/sddm/scripts/Xsetup
    echo "✅ SDDM will use DisplayPort as primary and disable connected HDMI outputs"
fi
