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

trap 'hdr-set off "$owner"' EXIT
trap 'if [[ -n $child ]]; then kill -s INT -- "-$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; fi' INT
trap 'if [[ -n $child ]]; then kill -s TERM -- "-$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; fi' TERM
hdr-set on "$owner" "$$"

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
