#!/bin/bash

adjust_volume() {
    local sink="$1"
    local change="$2"

    # Get current volume of first channel (left)
    current=$(pactl get-sink-volume "$sink" | awk '{print $5}' | head -n 1 | tr -d '%')
    new=$((current + change))

    # Clamp between 0 and 100
    if [ "$new" -gt 100 ]; then
        new=100
    elif [ "$new" -lt 0 ]; then
        new=0
    fi

    pactl set-sink-volume "$sink" "${new}%"
}

adjust_volume discord_sink 2
adjust_volume catchall_sink -2
