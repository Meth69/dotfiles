#!/bin/bash
# Toggle between workspace 3 (Firefox) and previous workspace

current=$(hyprctl activeworkspace -j | jq -r .id)

if [ "$current" -eq 3 ]; then
    hyprctl dispatch workspace previous
else
    hyprctl dispatch workspace 3
fi
