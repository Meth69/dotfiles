#!/bin/bash
# Firefox Wayland compatibility tweaks for Hyprland fractional scaling.

set -euo pipefail

pref_name="widget.wayland.fractional-scale.enabled"
pref_line='user_pref("widget.wayland.fractional-scale.enabled", false);'
firefox_dir="$HOME/.mozilla/firefox"

echo "🦊 Configuring Firefox Wayland compatibility..."

if [ ! -d "$firefox_dir" ]; then
    echo "⚠️  Firefox profile directory not found. Open Firefox once, then run: ~/scripts/setup-firefox-wayland.sh"
    exit 0
fi

shopt -s nullglob
profiles=("$firefox_dir"/*.default "$firefox_dir"/*.default-*)
shopt -u nullglob

if [ "${#profiles[@]}" -eq 0 ]; then
    echo "⚠️  Firefox profile not found. Open Firefox once, then run: ~/scripts/setup-firefox-wayland.sh"
    exit 0
fi

updated=0
for profile in "${profiles[@]}"; do
    [ -d "$profile" ] || continue

    user_js="$profile/user.js"
    touch "$user_js"

    if grep -q "user_pref(\"$pref_name\"" "$user_js"; then
        tmp="$(mktemp)"
        sed "s|^user_pref(\"$pref_name\".*|$pref_line|" "$user_js" > "$tmp"
        mv "$tmp" "$user_js"
    else
        printf '\n%s\n' "$pref_line" >> "$user_js"
    fi

    echo "✅ Firefox Wayland fractional scaling disabled in $user_js"
    updated=$((updated + 1))
done

if [ "$updated" -eq 0 ]; then
    echo "⚠️  Firefox profile not found. Open Firefox once, then run: ~/scripts/setup-firefox-wayland.sh"
fi
