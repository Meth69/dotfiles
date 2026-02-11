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

# 6. Set zsh as default shell
if [ "$SHELL" != "/bin/zsh" ]; then
    echo ""
    echo "🐚 Setting zsh as default shell..."
    chsh -s /bin/zsh
    echo "✅ Default shell changed to zsh (logout/login to apply)"
else
    echo "✅ zsh is already the default shell"
fi

# 7. Install oh-my-zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "📦 Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ oh-my-zsh installed"
else
    echo "✅ oh-my-zsh already installed"
fi

# 8. Optional: Run claude-glm installer
echo ""
read -p "Install claude-glm wrappers? (y/n): " glm_choice < /dev/tty
if [[ "$glm_choice" == "y" || "$glm_choice" == "Y" ]]; then
    bash ~/scripts/claude-glm.sh
fi

# 9. Reload shell
echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "📝 Next steps:"
echo "   source ~/.zshrc     # Reload shell config"
echo "   dotfiles status     # Check dotfiles repo status"
