#!/bin/bash

# Get CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

# Get CPU temperature from sensors (Tctl for AMD CPUs)
CPU_TEMP=$(sensors 2>/dev/null | grep "Tctl" | awk '{print $2}' | sed 's/+//' | sed 's/°C//')

# Fallback: try Package/Temp inputs for Intel
if [ -z "$CPU_TEMP" ]; then
    CPU_TEMP=$(sensors 2>/dev/null | grep -m 1 "Package id 0\|Core 0" | awk '{print $3}' | sed 's/+//' | sed 's/°C//')
fi

# Round CPU usage
CPU_USAGE_INT=${CPU_USAGE%.*}

# If temp is still empty, use a placeholder
if [ -z "$CPU_TEMP" ]; then
    echo "{\"text\": \"󰍛 ${CPU_USAGE_INT}%\", \"tooltip\": \"CPU usage: ${CPU_USAGE_INT}%\"}"
else
    echo "{\"text\": \"󰍛 ${CPU_USAGE_INT}% ${CPU_TEMP}°C\", \"tooltip\": \"CPU usage: ${CPU_USAGE_INT}%\\nTemperature: ${CPU_TEMP}°C\"}"
fi
