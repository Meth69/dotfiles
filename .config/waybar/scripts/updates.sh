#!/bin/bash

# Get pacman updates
pacman_updates=$(pacman -Qu 2>/dev/null | wc -l)

# Get AUR updates via yay
aur_updates=$(yay -Qua 2>/dev/null | wc -l)

total=$((pacman_updates + aur_updates))

if [ "$total" -eq 0 ]; then
    echo '{"text": "", "tooltip": "System up to date", "class": "updated"}'
elif [ "$total" -eq 1 ]; then
    echo "{\"text\": \"$total\", \"tooltip\": \"$pacman_updates pacman / $aur_updates AUR\", \"class\": \"updates\"}"
else
    echo "{\"text\": \"$total\", \"tooltip\": \"$pacman_updates pacman / $aur_updates AUR\", \"class\": \"updates\"}"
fi
