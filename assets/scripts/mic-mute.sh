#!/usr/bin/env bash

wpctl_cmd="${MIC_MUTE_WPCTL:-wpctl}"
dms_cmd="${MIC_MUTE_DMS:-dms}"

last_state=""

get_state() {
  "$wpctl_cmd" get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo "muted" || echo "unmuted"
}

while true; do
  current_state=$(get_state)

  if [[ $current_state != "$last_state" ]]; then
    if [[ $current_state == "muted" ]]; then
      "$dms_cmd" brightness set leds:platform::micmute 100
    else
      "$dms_cmd" brightness set leds:platform::micmute 0
    fi

    last_state="$current_state"
  fi

  sleep 0.1
done
