#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$TMPDIR/bin"
export STATE="$TMPDIR/mic-state" DMS_LOG="$TMPDIR/dms.log" WPCTL_LOG="$TMPDIR/wpctl.log"

cat >"$TMPDIR/bin/wpctl" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$WPCTL_LOG"
state=$(cat "$STATE" 2>/dev/null || echo unmuted)
if [ "$state" = muted ]; then
  echo "Volume: 0.50 [MUTED]"
else
  echo "Volume: 0.50"
fi
STUB

cat >"$TMPDIR/bin/dms" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$DMS_LOG"
STUB
chmod +x "$TMPDIR/bin/wpctl" "$TMPDIR/bin/dms"

export MIC_MUTE_WPCTL="$TMPDIR/bin/wpctl" MIC_MUTE_DMS="$TMPDIR/bin/dms"

[ -x "$MIC_MUTE_WPCTL" ] || fail "wpctl stub is not executable"
[ -x "$MIC_MUTE_DMS" ] || fail "dms stub is not executable"

: >"$WPCTL_LOG"
: >"$DMS_LOG"
printf 'muted\n' >"$STATE"
timeout 1 "$RUNNER" >/dev/null 2>&1 || true

dms_calls=$(grep -c 'brightness set' "$DMS_LOG" || true)
[ "$dms_calls" = 1 ] ||
  fail "a constant muted state must drive dms exactly once, got $dms_calls calls: $(cat "$DMS_LOG")"
grep -qxF 'brightness set leds:platform::micmute 100' "$DMS_LOG" ||
  fail "muted state did not raise the LED: $(cat "$DMS_LOG")"
wpctl_calls=$(grep -c . "$WPCTL_LOG" || true)
[ "$wpctl_calls" -gt 2 ] ||
  fail "the poll loop did not run (only $wpctl_calls wpctl calls), so the guard is unproven"

: >"$WPCTL_LOG"
: >"$DMS_LOG"
printf 'unmuted\n' >"$STATE"
timeout 1 "$RUNNER" >/dev/null 2>&1 || true

grep -qxF 'brightness set leds:platform::micmute 0' "$DMS_LOG" ||
  fail "unmuted state did not lower the LED: $(cat "$DMS_LOG")"
dms_calls=$(grep -c 'brightness set' "$DMS_LOG" || true)
[ "$dms_calls" = 1 ] ||
  fail "a constant unmuted state must drive dms exactly once, got $dms_calls"

: >"$WPCTL_LOG"
: >"$DMS_LOG"
printf 'muted\n' >"$STATE"
(
  sleep 0.4
  printf 'unmuted\n' >"$STATE"
) &
timeout 1 "$RUNNER" >/dev/null 2>&1 || true
wait

mapfile -t calls <"$DMS_LOG"
[ "${#calls[@]}" = 2 ] ||
  fail "a mid-run state change must drive exactly two dms calls, got ${#calls[@]}: $(cat "$DMS_LOG")"
[ "${calls[0]}" = "brightness set leds:platform::micmute 100" ] ||
  fail "first call should raise the LED: $(cat "$DMS_LOG")"
[ "${calls[1]}" = "brightness set leds:platform::micmute 0" ] ||
  fail "second call should lower the LED: $(cat "$DMS_LOG")"

echo "mic-mute: all assertions hold"
