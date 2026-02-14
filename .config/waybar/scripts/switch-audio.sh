#!/bin/bash
# Switch default audio output via wofi

default=$(pactl get-default-sink)

# Friendly name overrides: sink_name -> display name
friendly_name() {
    case "$1" in
        alsa_output.pci-0000_03_00.1.hdmi-stereo)
            echo "Gigabyte 4K (DP)" ;;
        alsa_output.usb-SteelSeries_SteelSeries_Arctis_1_Wireless-00.analog-stereo)
            echo "SteelSeries Arctis 1 Wireless" ;;
        *)
            echo "" ;;  # empty = hidden
    esac
}

# Build display list
display=""
while IFS='|' read -r name; do
    label=$(friendly_name "$name")
    [ -z "$label" ] && continue

    if [ "$name" = "$default" ]; then
        display+="󰕾  $label  ✓\n"
    else
        display+="󰖀  $label\n"
    fi
done < <(pactl list sinks short | awk '{print $2}')

chosen=$(printf "$display" | wofi --dmenu \
    --prompt "Audio Output" \
    --width 380 \
    --height 160 \
    --no-actions \
    --insensitive)

[ -z "$chosen" ] && exit

# Strip icon prefix and active marker to get the label
label=$(echo "$chosen" | sed 's/^[^ ]* *//' | sed 's/  ✓$//')

# Find sink name matching the label
while IFS='|' read -r name; do
    if [ "$(friendly_name "$name")" = "$label" ]; then
        pactl set-default-sink "$name"
        break
    fi
done < <(pactl list sinks short | awk '{print $2}')
