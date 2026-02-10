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

# 4. Ask what to install
echo ""
echo -e "${YELLOW}What would you like to install?${NC}"
echo "1) Core packages only"
echo "2) Core + GUI"
echo "3) Core + GUI + Hardware"
echo "4) Everything (including AUR)"
echo "5) Skip package installation"
read -p "Choice (1-5): " choice

case $choice in
    1)
        echo "📦 Installing core packages..."
        sudo pacman -S --needed - < ~/packages-core.txt
        ;;
    2)
        echo "📦 Installing core + GUI packages..."
        sudo pacman -S --needed - < ~/packages-core.txt
        sudo pacman -S --needed - < ~/packages-gui.txt
        ;;
    3)
        echo "📦 Installing core + GUI + hardware packages..."
        echo "⚠️  Review packages-hardware.txt first for your hardware!"
        read -p "Press Enter to continue..."
        sudo pacman -S --needed - < ~/packages-core.txt
        sudo pacman -S --needed - < ~/packages-gui.txt
        sudo pacman -S --needed - < ~/packages-hardware.txt
        ;;
    4)
        echo "📦 Installing everything..."
        echo "⚠️  Review packages-hardware.txt first for your hardware!"
        read -p "Press Enter to continue..."
        sudo pacman -S --needed - < ~/packages-core.txt
        sudo pacman -S --needed - < ~/packages-gui.txt
        sudo pacman -S --needed - < ~/packages-hardware.txt
        yay -S --needed - < ~/aur.txt
        ;;
    5)
        echo "⏭️  Skipping package installation"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# 5. Optional: Run claude-glm installer
echo ""
read -p "Install claude-glm wrappers? (y/n): " glm_choice
if [[ "$glm_choice" == "y" || "$glm_choice" == "Y" ]]; then
    bash ~/scripts/claude-glm.sh
fi

# 6. Reload shell
echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "📝 Next steps:"
echo "   source ~/.zshrc     # Reload shell config"
echo "   dotfiles status     # Check dotfiles repo status"
