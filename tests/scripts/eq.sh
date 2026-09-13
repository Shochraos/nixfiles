#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$XDG_STATE_HOME/audio-eq"

out=$(eq)
first_line=$(printf '%s\n' "$out" | sed -n '1p')
device=$(printf '%s' "$first_line" | cut -d: -f1)
loaded=$(printf '%s' "$first_line" | cut -d: -f2- | tr -d ' ')

[ -n "$device" ] || fail "no equalizer reported: $out"
case "$loaded" in
off | unknown) ;;
*) fail "unexpected loaded preset '$loaded' in: $first_line" ;;
esac
printf '%s\n' "$out" | grep -qE '^  presets: .* off$' || fail "preset list missing: $out"

presets=$(printf '%s\n' "$out" | sed -n 's/^  presets: \(.*\) off$/\1/p')
preset=$(printf '%s' "$presets" | awk '{ print $1 }')
[ -n "$preset" ] || fail "no preset names advertised: $out"

state="$XDG_STATE_HOME/audio-eq/$device"

if eq bogus 2>"$TMPDIR/err"; then fail "'eq bogus' exited 0"; fi
grep -q "has no preset 'bogus'" "$TMPDIR/err" || fail "unknown preset not reported"
if [ -e "$state" ]; then fail "a rejected preset still wrote $state"; fi

if eq nosuchdevice "$preset" 2>"$TMPDIR/err"; then fail "'eq nosuchdevice' exited 0"; fi
grep -q 'unknown equalizer' "$TMPDIR/err" || fail "unknown equalizer not reported"

if eq a b c 2>"$TMPDIR/err"; then fail "three arguments exited 0"; fi
grep -q 'usage: eq' "$TMPDIR/err" || fail "no usage on too many arguments"

eq --help >"$TMPDIR/help" || fail "--help exited non-zero"
grep -q 'usage: eq' "$TMPDIR/help" || fail "--help printed no usage"

eq "$preset" || true
[ "$(cat "$state" 2>/dev/null)" = "$preset" ] || fail "selecting '$preset' did not record it"

eq off || true
[ "$(cat "$state" 2>/dev/null)" = "off" ] || fail "'eq off' did not record off"

eq "$preset" || true
out=$(eq)
printf '%s\n' "$out" | grep -q "warning: '$preset' is selected but not loaded" ||
  fail "a stale selection was not warned about: $out"

echo "eq: all assertions hold"
