#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

loaded_of() {
  printf '%s\n' "$1" | sed -n '1p' | cut -d: -f2- | tr -d ' '
}

mkdir -p "$TMPDIR/bin" "$XDG_STATE_HOME/audio-eq" "$XDG_RUNTIME_DIR/audio-eq"
export SYSTEMCTL_LOG="$TMPDIR/systemctl.log"
: >"$SYSTEMCTL_LOG"

cat >"$TMPDIR/bin/systemctl" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$SYSTEMCTL_LOG"
if [ "${2:-}" = is-active ]; then
  exit "${IS_ACTIVE_RC:-1}"
fi
exit 0
STUB
chmod +x "$TMPDIR/bin/systemctl"

export PATH="$TMPDIR/bin:$PATH"

resolved=$(command -v systemctl)
[ "$resolved" = "$TMPDIR/bin/systemctl" ] ||
  fail "systemctl stub does not shadow the ambient binary: $resolved"

out=$(eq)
first_line=$(printf '%s\n' "$out" | sed -n '1p')
device=$(printf '%s' "$first_line" | cut -d: -f1)
loaded=$(loaded_of "$out")

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
runtime="$XDG_RUNTIME_DIR/audio-eq/$device"

if eq bogus 2>"$TMPDIR/err"; then fail "'eq bogus' exited 0"; fi
grep -q "has no preset 'bogus'" "$TMPDIR/err" || fail "unknown preset not reported"
if [ -e "$state" ]; then fail "a rejected preset still wrote $state"; fi

if eq nosuchdevice "$preset" 2>"$TMPDIR/err"; then fail "'eq nosuchdevice' exited 0"; fi
grep -q 'unknown equalizer' "$TMPDIR/err" || fail "unknown equalizer not reported"

if eq a b c 2>"$TMPDIR/err"; then fail "three arguments exited 0"; fi
grep -q 'usage: eq' "$TMPDIR/err" || fail "no usage on too many arguments"

eq --help >"$TMPDIR/help" || fail "--help exited non-zero"
grep -q 'usage: eq' "$TMPDIR/help" || fail "--help printed no usage"

eq "$preset"
[ "$(cat "$state" 2>/dev/null)" = "$preset" ] || fail "selecting '$preset' did not record it"
grep -qxF -- "--user restart pipewire-eq-$device.service" "$SYSTEMCTL_LOG" ||
  fail "selecting a preset did not restart the unit"

eq off
[ "$(cat "$state" 2>/dev/null)" = "off" ] || fail "'eq off' did not record off"
grep -qxF -- "--user stop pipewire-eq-$device.service" "$SYSTEMCTL_LOG" ||
  fail "'eq off' did not stop the unit"

rm -f "$runtime"
out=$(IS_ACTIVE_RC=0 eq)
[ "$(loaded_of "$out")" = unknown ] ||
  fail "an active unit with no runtime record must report 'unknown': $out"

printf '%s\n' "$preset" >"$runtime"
out=$(IS_ACTIVE_RC=0 eq)
[ "$(loaded_of "$out")" = "$preset" ] ||
  fail "an active unit must report its runtime record: $out"

out=$(IS_ACTIVE_RC=1 eq)
[ "$(loaded_of "$out")" = off ] ||
  fail "an inactive unit must report 'off': $out"

eq "$preset"
out=$(IS_ACTIVE_RC=1 eq)
printf '%s\n' "$out" | grep -q "warning: '$preset' is selected but not loaded" ||
  fail "a stale selection was not warned about: $out"

echo "eq: all assertions hold"
