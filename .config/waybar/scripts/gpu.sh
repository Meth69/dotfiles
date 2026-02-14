#!/bin/bash
GPU_USAGE=$(cat /sys/class/drm/card1/device/gpu_busy_percent)
GPU_TEMP=$(( $(cat /sys/class/hwmon/hwmon2/temp1_input) / 1000 ))
echo "{\"text\": \"󰢮 ${GPU_USAGE}% ${GPU_TEMP}°C\", \"tooltip\": \"GPU usage: ${GPU_USAGE}%\\nTemperature: ${GPU_TEMP}°C\"}"
