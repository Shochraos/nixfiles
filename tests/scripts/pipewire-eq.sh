#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -n "${RUNNER:-}" ] || fail "RUNNER is not set"
[ -x "$RUNNER" ] || fail "RUNNER is not executable: $RUNNER"
base=${RUNNER##*/}
device=${base#pipewire-eq-}
[ "$device" != "$base" ] || fail "cannot derive a device name out of $base"

mkdir -p "$TMPDIR/bin" "$XDG_STATE_HOME/audio-eq" "$XDG_RUNTIME_DIR/audio-eq"
export PIPEWIRE_LOG="$TMPDIR/pipewire.log"

cat >"$TMPDIR/bin/pipewire" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$PIPEWIRE_LOG"
exit 0
STUB
chmod +x "$TMPDIR/bin/pipewire"
export PIPEWIRE="$TMPDIR/bin/pipewire"

state="$XDG_STATE_HOME/audio-eq/$device"
runtime="$XDG_RUNTIME_DIR/audio-eq/$device"

out=$(eq)
presets=$(printf '%s\n' "$out" | sed -n 's/^  presets: \(.*\) off$/\1/p')
[ -n "$presets" ] || fail "eq advertised no presets: $out"

: >"$PIPEWIRE_LOG"
rm -f "$state" "$runtime"
err=$("$RUNNER" 2>&1 >/dev/null)
default=$(sed -n 's/.* loading \(.*\)$/\1/p' <<<"$err")
[ -n "$default" ] || fail "the runner loaded nothing without a state record: $err"
grep -q '^-c ' "$PIPEWIRE_LOG" || fail "pipewire was not started: $(cat "$PIPEWIRE_LOG")"
conf=$(sed -n 's/^-c \(.*\)$/\1/p' "$PIPEWIRE_LOG")
[ -f "$conf" ] || fail "the runner pointed pipewire at a missing conf: $conf"
jq -e 'type == "object"' "$conf" >/dev/null || fail "the generated conf is not a JSON object: $conf"
grep -q "effect_input.$device" "$conf" || fail "the conf does not build the $device filter: $conf"
grep -q '"preamp"' "$conf" || fail "the conf carries no preamp node: $conf"
grep -q 'filter.smart.target' "$conf" || fail "the conf does not name a smart-filter target: $conf"
[ "$(cat "$runtime")" = "$default" ] ||
  fail "the runtime record should hold the default, got: $(cat "$runtime")"

seen="$TMPDIR/seen-confs"
: >"$seen"
read -ra preset_list <<<"$presets"
for preset in "${preset_list[@]}"; do
  : >"$PIPEWIRE_LOG"
  printf '%s\n' "$preset" >"$state"
  rm -f "$runtime"
  err=$("$RUNNER" 2>&1 >/dev/null)
  grep -q "loading $preset\$" <<<"$err" || fail "preset '$preset' was not loaded: $err"
  [ "$(cat "$runtime")" = "$preset" ] ||
    fail "the runtime record did not follow '$preset': $(cat "$runtime")"
  preset_conf=$(sed -n 's/^-c \(.*\)$/\1/p' "$PIPEWIRE_LOG")
  if grep -qxF "$preset_conf" "$seen"; then
    fail "preset '$preset' reused another preset's graph: $preset_conf"
  fi
  printf '%s\n' "$preset_conf" >>"$seen"
done

: >"$PIPEWIRE_LOG"
printf 'off\n' >"$state"
rm -f "$runtime"
err=$("$RUNNER" 2>&1 >/dev/null)
grep -q 'runs no filter' <<<"$err" || fail "'off' was not honoured: $err"
[ ! -s "$PIPEWIRE_LOG" ] || fail "pipewire was started for 'off': $(cat "$PIPEWIRE_LOG")"
[ ! -e "$runtime" ] || fail "'off' still wrote a runtime record"

: >"$PIPEWIRE_LOG"
printf 'bogus\n' >"$state"
rm -f "$runtime"
err=$("$RUNNER" 2>&1 >/dev/null)
grep -q "has no preset bogus, loading $default" <<<"$err" ||
  fail "an unknown preset did not fall back to the default: $err"
[ "$(cat "$runtime")" = "$default" ] || fail "the fallback did not record the default"

echo "pipewire-eq: all assertions hold"
