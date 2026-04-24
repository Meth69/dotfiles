#!/bin/bash
# Random wallpaper selector

WALLPAPER_DIR="$HOME/.config/wallpapers"
CURRENT_LINK="$HOME/.config/wallpapers/current"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Get all wallpapers in the directory (nullglob prevents literal patterns for unmatched extensions)
shopt -s nullglob
wallpapers=("$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.jpeg)
shopt -u nullglob

if [[ ${#wallpapers[@]} -eq 0 ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Pick a random wallpaper
random_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"

# Create/update symlink
ln -sf "$random_wallpaper" "$CURRENT_LINK"

# Write hyprpaper config with absolute path (v0.8+ block syntax)
cat > "$HYPRPAPER_CONF" <<EOF
preload = $random_wallpaper
splash = false

wallpaper {
    monitor = HDMI-A-1
    path = $random_wallpaper
}

wallpaper {
    monitor = DP-1
    path = $random_wallpaper
}
EOF

echo "Selected wallpaper: $random_wallpaper"
