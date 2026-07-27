#!/usr/bin/env bash
set -euo pipefail

last_state=""

get_state() {
  wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo "muted" || echo "unmuted"
}

while true; do
  current_state=$(get_state)

  if [[ $current_state != "$last_state" ]]; then
    if [[ $current_state == "muted" ]]; then
      dms brightness set leds:platform::micmute 100
    else
      dms brightness set leds:platform::micmute 0
    fi

    last_state="$current_state"
  fi

  sleep 0.1
done
