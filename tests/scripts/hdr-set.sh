#!/usr/bin/env bash
set -euo pipefail

hdrdir="$HOME/.config/hypr/dms"
lua="$hdrdir/outputs.lua"
line='hl.monitor({ output = "HDMI-A-1", cm = "hdredid" })'
clients="$TMPDIR/clients"
game=steam_app_0000000000

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

count() { grep -cxF "$line" "$lua" 2>/dev/null || true; }

# A real script in PATH, because the wrapper calls hyprctl in a child process.
write_hyprctl() {
  cat >"$TMPDIR/bin/hyprctl" <<'STUB'
#!/bin/sh
case "$1" in
  clients)
    printf '['
    first=1
    while read -r class; do
      [ -n "$class" ] || continue
      [ "$first" = 1 ] || printf ','
      printf '{"class":"%s"}' "$class"
      first=0
    done <"$CLIENTS"
    printf ']\n'
    ;;
  *)
    echo "hyprctl $*" >>"$HYPRCTL_LOG"
    ;;
esac
STUB
  chmod +x "$TMPDIR/bin/hyprctl"
  : >"$HYPRCTL_LOG"
}

mkdir -p "$hdrdir" "$TMPDIR/bin"
export CLIENTS="$clients" HYPRCTL_LOG="$TMPDIR/hyprctl.log"
write_hyprctl
export PATH="$TMPDIR/bin:$PATH"

printf 'spotify\n' >"$clients"

hdr-set on
[ -f "$lua" ] || fail "on did not create $lua"
[ "$(count)" = 1 ] || fail "on should leave exactly one line, got $(count)"
grep -q 'hyprctl reload' "$HYPRCTL_LOG" || fail "on did not reload hyprland"

hdr-set on
[ "$(count)" = 1 ] || fail "on is not idempotent, got $(count)"

if hdr-set bogus 2>"$TMPDIR/err"; then fail "bogus arg exited 0"; fi
grep -q 'usage: hdr-set on|off' "$TMPDIR/err" || fail "bogus arg did not print usage"

printf '#!/bin/sh\nexit 1\n' >"$TMPDIR/bin/hyprctl"
chmod +x "$TMPDIR/bin/hyprctl"
hdr-set on || fail "a failing hyprctl must not fail hdr-set"
write_hyprctl

hdr-set off
[ "$(count)" = 0 ] || fail "off did not remove the line"
hdr-set off || fail "off on a clean file must exit 0"

printf '%s\n' "$line" >"$lua"
hdr-set off
[ -f "$lua" ] || fail "off deleted the file instead of emptying it"

export HDR_POLL_INTERVAL=0.2 HDR_GRACE=1

# The reported bug: a launcher that spawns the game window and exits at once
# must not switch HDR off. HDR follows the window, not the wrapped process.
cat >"$TMPDIR/bin/game" <<'GAME'
#!/bin/sh
printf 'spotify\n%s\n' "$GAME_CLASS" >"$CLIENTS"
sleep 2
grep -cF "$HDR_LINE" "$HOME/.config/hypr/dms/outputs.lua" >"$DURING" || true
printf 'spotify\n' >"$CLIENTS"
sleep 5
GAME
chmod +x "$TMPDIR/bin/game"

cat >"$TMPDIR/bin/launcher" <<'LAUNCHER'
#!/bin/sh
setsid "$TMPDIR/bin/game" >/dev/null 2>&1 &
exit 0
LAUNCHER
chmod +x "$TMPDIR/bin/launcher"

: >"$lua"
printf 'spotify\n' >"$clients"
export GAME_CLASS="$game" HDR_LINE="$line" DURING="$TMPDIR/during" HDR_HANDOFF=15
: >"$DURING"

start=$(date +%s)
hdr "$TMPDIR/bin/launcher" || fail "hdr must propagate the launcher's zero exit"
elapsed=$(($(date +%s) - start))

[ "$(count)" = 0 ] || fail "hdr did not restore after the game window closed"
[ "$elapsed" -lt 15 ] ||
  fail "hdr outlived the game window and fell back to the handoff timeout (${elapsed}s)"
[ "$(cat "$DURING")" = 1 ] ||
  fail "HDR was off while the game window was open: hdr followed the launcher's exit, not the window"

# A short handoff keeps the no-window case from stalling the check.
export HDR_HANDOFF=1
hdr false && fail "the hdr wrapper must propagate a non-zero child exit"
[ "$(count)" = 0 ] || fail "the hdr wrapper did not restore after a failing child"
hdr true || fail "the hdr wrapper must propagate a zero exit"
[ "$(count)" = 0 ] || fail "the hdr wrapper did not restore after a successful child"

echo "hdr-set: all assertions hold"
