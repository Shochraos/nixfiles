#!/bin/bash

DISCORD_SINK="${DISCORD_SINK:-discord_sink}"
CATCHALL_SINK="${CATCHALL_SINK:-catchall_sink}"
STEP=2

set_volume() {
  pactl set-sink-volume "$1" "${2}%"
}

adjust_volume() {
  local sink="$1"
  local change="$2"

  # Get current volume of first channel (left)
  current=$(pactl get-sink-volume "$sink" | awk 'NR==1 { gsub(/%/, "", $5); print $5 }')
  new=$((current + change))

  # Clamp between 0 and 100
  if [ "$new" -gt 100 ]; then
    new=100
  elif [ "$new" -lt 0 ]; then
    new=0
  fi

  set_volume "$sink" "$new"
}

shift_balance() {
  adjust_volume "$DISCORD_SINK" "$1"
  adjust_volume "$CATCHALL_SINK" "$2"
}

case "${1:-}" in
chat) shift_balance "$STEP" "-$STEP" ;;
game) shift_balance "-$STEP" "$STEP" ;;
reset)
  set_volume "$DISCORD_SINK" 50
  set_volume "$CATCHALL_SINK" 50
  ;;
*)
  echo "usage: ${0##*/} chat|game|reset" >&2
  exit 1
  ;;
esac
