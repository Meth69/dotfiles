#!/bin/bash
# Dotfiles Bootstrap Script
# Run on fresh Arch install: curl -sL https://github.com/Meth69/dotfiles/raw/main/bootstrap.sh | bash

set -e

echo "🚀 Dotfiles Bootstrap"
echo "====================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running on Arch
if [ ! -f /etc/arch-release ]; then
    echo "❌ This script is designed for Arch Linux"
    exit 1
fi

# 1. Install base dependencies if missing
echo "📦 Checking base dependencies..."
sudo pacman -S --needed --noconfirm base-devel git

# 2. Clone dotfiles
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "📥 Cloning dotfiles..."
    git clone --bare https://github.com/Meth69/dotfiles.git $HOME/.dotfiles
    dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
    $dotfiles config status.showUntrackedFiles no
    $dotfiles checkout
else
    echo "✅ Dotfiles already cloned"
    dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
fi

# 3. Install yay if not present
if ! command -v yay &> /dev/null; then
    echo "📦 Installing yay (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
    echo "✅ yay installed"
else
    echo "✅ yay already installed"
fi

# 4. Hardware profile selection
echo ""
echo -e "${YELLOW}Select hardware profile:${NC}"
echo "1) AMD Desktop (with GPU drivers)"
echo "2) Intel Laptop (minimal - auto-detected)"
echo "3) Skip hardware packages"
read -p "Choice (1-3): " hw_choice < /dev/tty

hardware_file=""
case $hw_choice in
    1)
        hardware_file="$HOME/packages/hardware/amd-desktop.txt"
        echo "📦 Selected: AMD Desktop"
        ;;
    2)
        hardware_file="$HOME/packages/hardware/laptop.txt"
        echo "📦 Selected: Intel Laptop"
        ;;
    3)
        echo "⏭️  Skipping hardware packages"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# 5. Ask what to install
echo ""
echo -e "${YELLOW}What would you like to install?${NC}"
echo "1) Core packages only"
echo "2) Core + GUI"
echo "3) Core + GUI + Hardware (selected above)"
echo "4) Everything (including AUR)"
echo "5) Skip package installation"
read -p "Choice (1-5): " choice < /dev/tty

case $choice in
    1)
        echo "📦 Installing core packages..."
        grep -vE '^(#|$)' ~/packages/core.txt | sudo pacman -S --needed -
        ;;
    2)
        echo "📦 Installing core + GUI packages..."
        grep -vE '^(#|$)' ~/packages/core.txt | sudo pacman -S --needed -
        grep -vE '^(#|$)' ~/packages/gui.txt | sudo pacman -S --needed -
        ;;
    3)
        if [ -z "$hardware_file" ]; then
            echo "❌ No hardware profile selected!"
            exit 1
        fi
        echo "📦 Installing core + GUI + hardware packages..."
        grep -vE '^(#|$)' ~/packages/core.txt | sudo pacman -S --needed -
        grep -vE '^(#|$)' ~/packages/gui.txt | sudo pacman -S --needed -
        grep -vE '^(#|$)' "$hardware_file" | sudo pacman -S --needed -
        ;;
    4)
        if [ -z "$hardware_file" ]; then
            echo "⚠️  No hardware profile selected, skipping hardware packages"
            grep -vE '^(#|$)' ~/packages/core.txt | sudo pacman -S --needed -
            grep -vE '^(#|$)' ~/packages/gui.txt | sudo pacman -S --needed -
        else
            grep -vE '^(#|$)' ~/packages/core.txt | sudo pacman -S --needed -
            grep -vE '^(#|$)' ~/packages/gui.txt | sudo pacman -S --needed -
            grep -vE '^(#|$)' "$hardware_file" | sudo pacman -S --needed -
        fi
        grep -vE '^(#|$)' ~/packages/aur.txt | yay -S --needed -
        ;;
    5)
        echo "⏭️  Skipping package installation"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# 6. Enable NetworkManager (required for wifi/network tray icon)
echo ""
echo "🌐 Enabling NetworkManager..."
if systemctl is-active --quiet NetworkManager; then
    echo "✅ NetworkManager already running"
else
    sudo systemctl enable --now NetworkManager
    echo "✅ NetworkManager enabled and started"
fi

# Disable systemd-networkd-wait-online (conflicts with NetworkManager, causes 2min boot delay)
if systemctl is-enabled --quiet systemd-networkd-wait-online.service 2>/dev/null; then
    sudo systemctl disable systemd-networkd-wait-online.service
    echo "✅ Disabled systemd-networkd-wait-online (not needed with NetworkManager)"
fi

# 7. Configure SDDM (theme + monitor fix for desktop)
sddm_profile=""
[ "$hw_choice" = "1" ] && sddm_profile="desktop"
bash ~/scripts/setup-sddm.sh $sddm_profile

# 8. Set zsh as default shell
if [ "$SHELL" != "/bin/zsh" ]; then
    echo ""
    echo "🐚 Setting zsh as default shell..."
    chsh -s /bin/zsh
    echo "✅ Default shell changed to zsh (logout/login to apply)"
else
    echo "✅ zsh is already the default shell"
fi

# 9. Install oh-my-zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "📦 Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # Restore .zshrc from dotfiles repo (oh-my-zsh may have modified it)
    $dotfiles checkout -- .zshrc
    echo "✅ oh-my-zsh installed"
else
    echo "✅ oh-my-zsh already installed"
fi

# 10. Optional: Setup SSH for NAS access
echo ""
read -p "Setup SSH key and config for NAS access? (y/n): " ssh_choice < /dev/tty
if [[ "$ssh_choice" == "y" || "$ssh_choice" == "Y" ]]; then
    bash ~/scripts/setup-ssh.sh
fi

# 11. Optional: Setup NFS mounts from TrueNAS
echo ""
read -p "Setup NFS mounts from TrueNAS? (y/n): " nfs_choice < /dev/tty
if [[ "$nfs_choice" == "y" || "$nfs_choice" == "Y" ]]; then
    bash ~/scripts/setup-nfs-mounts.sh
fi

# 12. Optional: Install Hyprland
echo ""
read -p "Install Hyprland? (y/n): " hypr_choice < /dev/tty
if [[ "$hypr_choice" == "y" || "$hypr_choice" == "Y" ]]; then
    echo "📦 Installing Hyprland packages..."
    grep -vE '^(#|$)' ~/packages/hyprland.txt | sudo pacman -S --needed -
    grep -vE '^(#|$)' ~/packages/aur-hyprland.txt | yay -S --needed -
    bash ~/scripts/setup-hyprland.sh
fi

# 13. Optional: Setup printing (CUPS + driverless IPP)
echo ""
read -p "Setup printing support (CUPS + network printer discovery)? (y/n): " print_choice < /dev/tty
if [[ "$print_choice" == "y" || "$print_choice" == "Y" ]]; then
    echo "📦 Installing CUPS and nss-mdns..."
    sudo pacman -S --needed --noconfirm cups nss-mdns
    echo "🔧 Enabling cups and avahi-daemon..."
    sudo systemctl enable --now cups.service avahi-daemon.service
    # Add mdns_minimal to nsswitch.conf for .local printer discovery (idempotent)
    if ! grep -q 'mdns_minimal' /etc/nsswitch.conf; then
        sudo sed -i 's/^hosts: mymachines resolve/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve/' /etc/nsswitch.conf
        echo "✅ nsswitch.conf updated for mDNS"
    else
        echo "✅ nsswitch.conf already configured for mDNS"
    fi
    sudo usermod -aG lp "$USER"
    echo "✅ Printing setup complete (re-login for lp group to take effect)"
    echo "   Add your printer at: http://localhost:631"
fi

# 14. Install yazi packages (flavors, plugins)
if command -v ya &> /dev/null; then
    echo ""
    echo "📦 Installing yazi packages..."
    ya pkg install
    echo "✅ Yazi packages installed"
fi

# 15. Setup Claude Code configuration
bash ~/scripts/setup-claude.sh

# 16. Steam crash fix (AMD + Mesa 26 regression workaround)
if pacman -Q steam &>/dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}🎮 Steam crash fix${NC}"
    mkdir -p ~/.local/share/applications
    if [ -f ~/.local/share/applications/steam.desktop ]; then
        echo "✅ Steam desktop override in place (STEAM_DISABLE_GPU_PROCESS=1, PrefersNonDefaultGPU=false)"
    else
        echo "⚠️  Steam desktop override missing — run: dotfiles checkout -- .local/share/applications/steam.desktop"
    fi
fi

# 17. Reload shell
echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "📝 Next steps:"
echo "   source ~/.zshrc     # Reload shell config"
echo "   dotfiles status     # Check dotfiles repo status"
