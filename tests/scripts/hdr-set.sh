#!/usr/bin/env bash
set -euo pipefail

hdrdir="$HOME/.config/hypr/dms"
lua="$hdrdir/outputs.lua"
line='hl.monitor({ output = "HDMI-A-1", cm = "hdredid" })'

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

count() { grep -cxF "$line" "$lua" 2>/dev/null || true; }

stub_hyprctl() {
  printf '#!/bin/sh\necho "hyprctl $*" >> "%s"\n' "$TMPDIR/hyprctl.log" >"$TMPDIR/bin/hyprctl"
  chmod +x "$TMPDIR/bin/hyprctl"
}

mkdir -p "$hdrdir" "$TMPDIR/bin"
stub_hyprctl
export PATH="$TMPDIR/bin:$PATH"

hdr-set on
[ -f "$lua" ] || fail "on did not create $lua"
[ "$(count)" = 1 ] || fail "on should leave exactly one line, got $(count)"
grep -q 'hyprctl reload' "$TMPDIR/hyprctl.log" || fail "on did not reload hyprland"

hdr-set on
[ "$(count)" = 1 ] || fail "on is not idempotent, got $(count)"

if hdr-set bogus 2>"$TMPDIR/err"; then fail "bogus arg exited 0"; fi
grep -q 'usage: hdr-set on|off' "$TMPDIR/err" || fail "bogus arg did not print usage"

printf '#!/bin/sh\nexit 1\n' >"$TMPDIR/bin/hyprctl"
chmod +x "$TMPDIR/bin/hyprctl"
hdr-set on || fail "a failing hyprctl must not fail hdr-set"
stub_hyprctl

hdr-set off
[ "$(count)" = 0 ] || fail "off did not remove the line"
hdr-set off || fail "off on a clean file must exit 0"

hdr-set on
hdr true || fail "the hdr wrapper must propagate a zero exit"
[ "$(count)" = 0 ] || fail "the hdr wrapper did not restore on exit"

if hdr false; then fail "the hdr wrapper must propagate a non-zero child exit"; fi
[ "$(count)" = 0 ] || fail "the hdr wrapper did not restore after a failing child"

printf '%s\n' "$line" >"$lua"
hdr-set off
[ -f "$lua" ] || fail "off deleted the file instead of emptying it"

echo "hdr-set: all assertions hold"
