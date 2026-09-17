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

# A launch option inherits LD_LIBRARY_PATH from the Steam child environment,
# whose steam-runtime directories shadow newer Nix libraries (its 2019 libattr
# lacks ATTR_1.3, which coreutils' mktemp requires). A wrapper that runs its own
# tooling on that path dies at its first statement, before the game is spawned.
# The shadow lib must be a REAL ELF: the loader skips a truncated file outright,
# so an invalid one would not reproduce the failure at all.
shadow="$TMPDIR/shadow"
mkdir -p "$shadow"
install -m 644 "$SHADOW_LIB" "$shadow/libattr.so.1"

if LD_LIBRARY_PATH="$shadow" mktemp -d >/dev/null 2>&1; then
  fail "harness no longer bites: a shadowed libattr must break mktemp"
fi

cat >"$TMPDIR/bin/write-ld" <<'WRITELD'
#!/bin/sh
printf '%s\n' "${LD_LIBRARY_PATH-<unset>}" >"$LD_FILE"
WRITELD
chmod +x "$TMPDIR/bin/write-ld"

rm -f "$TMPDIR/child-ld"
export LD_FILE="$TMPDIR/child-ld"
LD_LIBRARY_PATH="$shadow" hdr "$TMPDIR/bin/write-ld" ||
  fail "hdr died on a shadowed library path instead of running its own tooling"
[ "$(cat "$LD_FILE" 2>/dev/null)" = "$shadow" ] ||
  fail "hdr did not hand the child the inherited library path"
[ "$(count)" = 0 ] || fail "hdr did not restore after the shadowed run"
unset LD_FILE

# A short handoff keeps the no-window case from stalling the check.
export HDR_HANDOFF=1
hdr false && fail "the hdr wrapper must propagate a non-zero child exit"
[ "$(count)" = 0 ] || fail "the hdr wrapper did not restore after a failing child"
hdr true || fail "the hdr wrapper must propagate a zero exit"
[ "$(count)" = 0 ] || fail "the hdr wrapper did not restore after a successful child"

echo "hdr-set: all assertions hold"
