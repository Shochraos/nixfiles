#!/usr/bin/env bash
set -euo pipefail

UNIT=macro-w-escape

if [[ ${MACRO_W_ESCAPE_CHILD:-} != 1 ]]; then
  if systemctl --user --quiet is-active "$UNIT.service"; then
    exec systemctl --user stop "$UNIT.service"
  fi
  exec systemd-run --user --unit="$UNIT" --collect \
    --setenv=MACRO_W_ESCAPE_CHILD=1 \
    -- "$(realpath "${BASH_SOURCE[0]}")"
fi

KEY_W=17
KEY_ESC=1
HOLD_SECONDS=30
PAUSE_SECONDS=17

release_keys() {
  ydotool key "$KEY_W:0" "$KEY_ESC:0"
}

trap 'exit 130' INT TERM
trap release_keys EXIT

while true; do
  ydotool key "$KEY_W:1"
  sleep "$HOLD_SECONDS"
  ydotool key "$KEY_W:0"
  ydotool key "$KEY_ESC:1" "$KEY_ESC:0"
  sleep "$PAUSE_SECONDS"
done
