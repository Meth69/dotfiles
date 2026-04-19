#!/bin/bash

set -euo pipefail

device=$(dualsensectl -l 2>/dev/null | awk '/\(Bluetooth\)/ {print $1; exit}')

if [ -z "$device" ] || ! bluetoothctl info "$device" 2>/dev/null | grep -q "Connected: yes"; then
  command -v notify-send >/dev/null 2>&1 && notify-send "DualSense" "Controller not connected"
  exit 1
fi

apply_color() {
  local red=$1 green=$2 blue=$3
  dualsensectl -d "$device" lightbar on >/dev/null 2>&1 || true
  dualsensectl -d "$device" lightbar off >/dev/null 2>&1 || true
  dualsensectl -d "$device" lightbar "$red" "$green" "$blue" 255 >/dev/null 2>&1 || true
  dualsensectl -d "$device" player-leds 1 >/dev/null 2>&1 || true
}

choice=$(printf '%s\n' \
  '🔵 Blue' \
  '⚪ White' \
  '🟣 Purple' \
  '🔴 Red' \
  '🟢 Green' \
  '🌈 Lightbar on' \
  '🌑 Lightbar off' \
  '💡 Player LED 1' \
  '🚫 Player LEDs off' \
  '⏻ Power off controller' | wofi --dmenu \
    --prompt 'DualSense' \
    --width 320 \
    --height 360 \
    --no-actions \
    --insensitive)

[ -z "${choice:-}" ] && exit 0

case "$choice" in
  '🔵 Blue')
    apply_color 0 0 255
    ;;
  '⚪ White')
    apply_color 255 255 255
    ;;
  '🟣 Purple')
    apply_color 160 64 255
    ;;
  '🔴 Red')
    apply_color 255 0 0
    ;;
  '🟢 Green')
    apply_color 0 255 0
    ;;
  '🌈 Lightbar on')
    dualsensectl -d "$device" lightbar on
    ;;
  '🌑 Lightbar off')
    dualsensectl -d "$device" lightbar off
    ;;
  '💡 Player LED 1')
    dualsensectl -d "$device" player-leds 1
    ;;
  '🚫 Player LEDs off')
    dualsensectl -d "$device" player-leds 0
    ;;
  '⏻ Power off controller')
    dualsensectl -d "$device" power-off
    ;;
esac
