#!/bin/bash
# Switch default audio output via wofi

set -euo pipefail

default=$(pactl get-default-sink)
hdmi_card="alsa_card.pci-0000_03_00.1"

friendly_name() {
    case "$1" in
        alsa_output.usb-SteelSeries_SteelSeries_Arctis_1_Wireless-00.analog-stereo)
            echo "SteelSeries Arctis 1 Wireless" ;;
        *)
            echo "" ;;
    esac
}

hdmi_active_profile() {
    pactl list cards | awk -v card="$hdmi_card" '
        $1 == "Name:" && $2 == card { in_card = 1; next }
        in_card && $1 == "Name:" { in_card = 0 }
        in_card && $1 == "Active" && $2 == "Profile:" { print $3; exit }
    '
}

has_hdmi_profile() {
    local profile="$1"
    pactl list cards | grep -q "^[[:space:]]*${profile}:"
}

switch_hdmi_target() {
    local profile="$1"
    local sink="$2"

    pactl set-card-profile "$hdmi_card" "$profile" >/dev/null

    for _ in $(seq 1 20); do
        if pactl list sinks short | awk '{print $2}' | grep -qx "$sink"; then
            break
        fi
        sleep 0.2
    done

    pactl set-default-sink "$sink"
}

add_option() {
    local label="$1"
    local is_active="$2"

    if [ "$is_active" = "yes" ]; then
        display+="󰕾  $label  ✓\n"
    else
        display+="󰖀  $label\n"
    fi
}

display=""
while IFS='|' read -r name; do
    label=$(friendly_name "$name")
    [ -z "$label" ] && continue

    if [ "$name" = "$default" ]; then
        add_option "$label" yes
    else
        add_option "$label" no
    fi
done < <(pactl list sinks short | awk '{print $2}')

if pactl list cards short | awk '{print $2}' | grep -qx "$hdmi_card"; then
    active_profile="$(hdmi_active_profile)"

    if has_hdmi_profile output:hdmi-stereo; then
        [ "$active_profile" = "output:hdmi-stereo" ] && add_option "Gigabyte 4K (DP)" yes || add_option "Gigabyte 4K (DP)" no
    fi

    if has_hdmi_profile output:hdmi-stereo-extra3; then
        [ "$active_profile" = "output:hdmi-stereo-extra3" ] && add_option "LG TV" yes || add_option "LG TV" no
    fi
fi

chosen=$(printf "$display" | wofi --dmenu \
    --prompt "Audio Output" \
    --width 380 \
    --height 200 \
    --no-actions \
    --insensitive)

[ -z "$chosen" ] && exit

# Strip icon prefix and active marker to get the label
label=$(echo "$chosen" | sed 's/^[^ ]* *//' | sed 's/  ✓$//')

case "$label" in
    "Gigabyte 4K (DP)")
        switch_hdmi_target output:hdmi-stereo alsa_output.pci-0000_03_00.1.hdmi-stereo ;;
    "SteelSeries Arctis 1 Wireless")
        pactl set-default-sink alsa_output.usb-SteelSeries_SteelSeries_Arctis_1_Wireless-00.analog-stereo ;;
    "LG TV")
        switch_hdmi_target output:hdmi-stereo-extra3 alsa_output.pci-0000_03_00.1.hdmi-stereo-extra3 ;;
esac
