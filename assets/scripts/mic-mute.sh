#!/usr/bin/env bash

wpctl_cmd="${MIC_MUTE_WPCTL:-wpctl}"
dms_cmd="${MIC_MUTE_DMS:-dms}"

last_state=""

get_state() {
  local volume
  volume=$("$wpctl_cmd" get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null) || return 1
  if [[ $volume == *MUTED* ]]; then
    printf 'muted\n'
  else
    printf 'unmuted\n'
  fi
}

while true; do
  if current_state=$(get_state) && [[ $current_state != "$last_state" ]]; then
    brightness=0
    if [[ $current_state == "muted" ]]; then
      brightness=100
    fi
    if "$dms_cmd" brightness set leds:platform::micmute "$brightness"; then
      last_state="$current_state"
    fi
  fi

  sleep 0.5
done
