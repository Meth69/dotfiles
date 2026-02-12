#!/bin/bash
# Setup NFS mounts from TrueNAS using systemd automount
# Run this after installing base system

set -e

NFS_HOST="truenas.local"
NFS_NVME_SHARE="/mnt/nvmepool/nvmeshare"
NFS_SPIN_SHARE="/mnt/spinningpool"
MOUNT_BASE="$HOME/nas"
NVME_MOUNT="$MOUNT_BASE/nvme"
SPIN_MOUNT="$MOUNT_BASE/spin"
FSTAB_MARK="# NFS shares from TrueNAS - systemd automount"

echo "📡 Setting up NFS mounts from TrueNAS..."

# Check if nfs-utils is installed
if ! pacman -Qi nfs-utils &>/dev/null; then
    echo "📦 Installing nfs-utils..."
    sudo pacman -S --noconfirm nfs-utils
else
    echo "✅ nfs-utils already installed"
fi

# Check if avahi is installed (for .local resolution)
if ! pacman -Qi avahi &>/dev/null; then
    echo "📦 Installing avahi for .local hostname resolution..."
    sudo pacman -S --noconfirm avahi
    sudo systemctl enable --now avahi-daemon
else
    echo "✅ avahi already installed"
    # Make sure avahi-daemon is running
    if ! systemctl is-active --quiet avahi-daemon; then
        sudo systemctl enable --now avahi-daemon
    fi
fi

# Create mount directories
echo "📁 Creating mount directories..."
mkdir -p "$NVME_MOUNT" "$SPIN_MOUNT"

# Check if fstab already has our entries
if grep -q "$NFS_NVME_SHARE" /etc/fstab 2>/dev/null; then
    echo "✅ fstab already contains NFS entries"
else
    echo "📝 Adding NFS entries to /etc/fstab..."
    sudo tee -a /etc/fstab > /dev/null << EOF

$FSTAB_MARK
$NFS_HOST:$NFS_NVME_SHARE  $NVME_MOUNT  nfs4  rw,noatime,x-systemd.automount,x-systemd.idle-timeout=600,_netdev  0  0
$NFS_HOST:$NFS_SPIN_SHARE  $SPIN_MOUNT  nfs4  rw,noatime,x-systemd.automount,x-systemd.idle-timeout=600,_netdev  0  0
EOF
fi

# Reload systemd to pick up new automount units
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# Enable and start the automount units
for mount in nvme spin; do
    unit="home-lysergic-nas-${mount}.automount"
    if systemctl list-unit-files | grep -q "^$unit"; then
        echo "🚀 Enabling $unit..."
        sudo systemctl enable "$unit"
        sudo systemctl start "$unit"
    fi
done

echo ""
echo "✅ NFS mounts configured!"
echo "   Mount points: ~/nas/nvme and ~/nas/spin"
echo "   Shares will automount on access and unmount after 10 minutes idle"
