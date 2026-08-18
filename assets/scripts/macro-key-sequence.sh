#!/usr/bin/env bash
set -euo pipefail

UNIT=macro-key-sequence

if [[ ${MACRO_KEY_SEQUENCE_CHILD:-} != 1 ]]; then
  if systemctl --user --quiet is-active "$UNIT.service"; then
    exec systemctl --user stop "$UNIT.service"
  fi
  systemctl --user stop 'macro-*.service'
  exec systemd-run --user --unit="$UNIT" --collect \
    --setenv=MACRO_KEY_SEQUENCE_CHILD=1 \
    -- "$(realpath "${BASH_SOURCE[0]}")"
fi

KEY_ESC=1
KEY_BACKSPACE=14
KEY_ENTER=28
KEY_A=30
KEY_D=32
KEY_UP=103
KEY_RIGHT=106
KEY_DOWN=108

SLOW_SECONDS=2.5
FAST_SECONDS=2
VERY_FAST_SECONDS=0.1

press() {
  local key
  local -a events=()
  for key in "$@"; do
    events+=("$key:1" "$key:0")
  done
  ydotool key "${events[@]}"
}

pressRepeated() {
  local count=$1 key=$2 i
  for ((i = 0; i < count; i++)); do
    #keys+=("$key")
    press key
  done
}

slow() {
  press "$@"
  sleep "$SLOW_SECONDS"
}

slowRepeated() {
  local count=$1 key=$2 i
  for ((i = 0; i < count; i++)); do
    press "$KEY_DOWN"
    sleep "$SLOW_SECONDS"
  done
}

fast() {
  press "$@"
  sleep "$FAST_SECONDS"
}

fastRepeated() {
  local count=$1 key=$2 i
  for ((i = 0; i < count; i++)); do
    press "$KEY_DOWN"
    sleep "$VERY_FAST_SECONDS"
  done
}

release_keys() {
  ydotool key "$KEY_ESC:0" "$KEY_BACKSPACE:0" "$KEY_ENTER:0" "$KEY_A:0" \
    "$KEY_D:0" "$KEY_UP:0" "$KEY_RIGHT:0" "$KEY_DOWN:0"
}

trap 'exit 130' INT TERM
trap release_keys EXIT

while true; do
  sleep "$FAST_SECONDS"
  slow "$KEY_ENTER"
  slow "$KEY_BACKSPACE"
  fastRepeated 11 "$KEY_DOWN"
  slow "$KEY_ENTER"
  slow "$KEY_RIGHT"
  slow "$KEY_RIGHT"
  slow "$KEY_RIGHT"
  slow "$KEY_DOWN"
  slow "$KEY_ENTER"
  sleep 8
  slow "$KEY_ENTER"
  slow "$KEY_ENTER"
  slow "$KEY_ENTER"
  slow "$KEY_ENTER"
  sleep 8
  slow "$KEY_ESC"
  slow "$KEY_D"
  slow "$KEY_DOWN"
  slow "$KEY_ENTER"
  fastRepeated 8 "$KEY_DOWN"
  slow "$KEY_ENTER"

  fast "$KEY_ENTER"
  fast "$KEY_RIGHT"
  fast "$KEY_ENTER"
  fast "$KEY_RIGHT"
  fast "$KEY_ENTER"
  fast "$KEY_UP"
  fast "$KEY_ENTER"
  fast "$KEY_UP"
  fast "$KEY_ENTER"
  fast "$KEY_UP"
  fast "$KEY_ENTER"
  fast "$KEY_ESC"
  fast "$KEY_ESC"
  fast "$KEY_A"
  fast "$KEY_UP"
done
