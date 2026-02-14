#!/bin/bash

if pgrep -x "yad" > /dev/null; then
    pkill yad
else
    yad --calendar \
        --display-month=$(date +%m) \
        --display-year=$(date +%Y) \
        --title="" \
        --no-buttons \
        --borders=10 \
        --geometry=280x250-10+44 &
fi
