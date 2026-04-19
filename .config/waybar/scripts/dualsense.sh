#!/bin/bash

set -euo pipefail

device=$(dualsensectl -l 2>/dev/null | awk '/\(Bluetooth\)/ {print $1; exit}')

[ -z "$device" ] && exit 1

bluetoothctl info "$device" 2>/dev/null | grep -q "Connected: yes" || exit 1

battery_raw=$(dualsensectl -d "$device" battery 2>/dev/null || true)
battery_pct=$(awk '{print $1}' <<< "$battery_raw")
battery_state=$(awk '{print $2}' <<< "$battery_raw")

if [[ -z "$battery_pct" || ! "$battery_pct" =~ ^[0-9]+$ ]]; then
  battery_pct="?"
fi

tooltip="DualSense\nBattery: ${battery_pct}%"
if [ -n "${battery_state:-}" ]; then
  tooltip+=" (${battery_state})"
fi
tooltip+="\nLeft click: controller menu"

class="normal"
if [[ "$battery_pct" =~ ^[0-9]+$ ]]; then
  if [ "$battery_pct" -le 20 ]; then
    class="critical"
  elif [ "$battery_pct" -le 50 ]; then
    class="warning"
  fi
fi

printf '{"text":" %s%%","tooltip":"%s","class":"%s"}\n' "$battery_pct" "$tooltip" "$class"
