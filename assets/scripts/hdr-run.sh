#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
  printf 'usage: hdr <foreground command> [arguments...]\n' >&2
  exit 2
fi

owner="game-$$"
child=""
launch_ld="${LD_LIBRARY_PATH-}"
unset LD_LIBRARY_PATH

release_hdr() {
  if ! hdr-set off "$owner" >/dev/null 2>&1; then
    printf 'hdr: HDR lease release failed; check hdr-set and compositor availability.\n' >&2 || true
  fi
}

trap 'rc=$?; release_hdr; exit "$rc"' EXIT
trap 'if [[ -n $child ]]; then kill -s INT -- "-$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; else exit 130; fi' INT
trap 'if [[ -n $child ]]; then kill -s TERM -- "-$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; else exit 143; fi' TERM
if ! hdr-set on "$owner" "$$" >/dev/null 2>&1; then
  release_hdr
  printf 'hdr: HDR acquisition failed; continuing without confirmed HDR setup. Check hdr-set and compositor availability.\n' >&2 || true
  timeout --kill-after=1s 2s notify-send --app-name=hdr --urgency=normal --expire-time=5000 \
    'HDR acquisition failed' \
    'Continuing without confirmed HDR setup. Check hdr-set and compositor availability.' >/dev/null 2>&1 || true
fi

if [[ -n $launch_ld ]]; then
  setsid env --default-signal=INT,QUIT LD_LIBRARY_PATH="$launch_ld" "$@" &
else
  setsid env --default-signal=INT,QUIT "$@" &
fi
child=$!

rc=0
wait "$child" || rc=$?
while kill -0 -- "-$child" 2>/dev/null; do
  sleep 0.2
done
exit "$rc"
