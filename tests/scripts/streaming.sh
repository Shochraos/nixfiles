#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$TMPDIR/bin"
export STREAM_POLL_INTERVAL=0.2 STREAM_GRACE=1 STREAM_HANDOFF=1
export MONITORS="$TMPDIR/monitors" CLIENTS="$TMPDIR/clients" HYPRCTL_LOG="$TMPDIR/hyprctl.log"
export MODES="$TMPDIR/modes" XDG_RUNTIME_DIR="$TMPDIR/run"
export CLIENT_MONITORS="$TMPDIR/client-monitors" ACTIVE_WINDOW="$TMPDIR/active-window"
export GAMESCOPE_PID_FILE="$TMPDIR/gamescope.pid"
export GAMESCOPE_LOG="$TMPDIR/gamescope.log"
mkdir -p "$XDG_RUNTIME_DIR"

cat >"$TMPDIR/bin/hyprctl" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$HYPRCTL_LOG"
case "$1" in
  monitors)
    jq -R -s --slurpfile m "$MODES" '
      split("\n") | map(select(length > 0))
      | to_entries
      | map({name: .value, id: .key, focused: (.key == 0), mode: ($m[0][.value] // "1920x1080@60")})
      | map(. as $e | . + {width: ($e.mode | split("x")[0] | tonumber),
                 height: ($e.mode | split("x")[1] | split("@")[0] | tonumber),
                 refreshRate: ($e.mode | split("@")[1] | tonumber)})
    ' <"$MONITORS"
    ;;
  activewindow)
    jq -n --arg a "$(cat "$ACTIVE_WINDOW" 2>/dev/null)" '{address: (if $a == "" then null else $a end)}'
    ;;
  clients)
    gspid=$(cat "$GAMESCOPE_PID_FILE" 2>/dev/null || echo 0)
    jq -R -s --slurpfile pm "$CLIENT_MONITORS" --argjson gspid "${gspid:-0}" '
      split("\n") | map(select(length > 0))
      | to_entries
      | map(.value as $c
            | ("0x" + ((.key + 1) | tostring)) as $a
            | {class: $c, address: $a, monitor: ($pm[0][$a] // 0),
               pid: (if $c == "gamescope" then $gspid else 0 end)})
    ' <"$CLIENTS"
    ;;
  output)
    exit 1
    ;;
  eval)
    eval_args="$*"
    mode_set=$(printf '%s\n' "$eval_args" | sed -n 's/.*output = "\([^"]*\)".*mode = "\([^"]*\)".*/\1 \2/p')
    if [ -n "$mode_set" ]; then
      set -- $mode_set
      jq --arg o "$1" --arg v "$2" '. + {($o): $v}' "$MODES" >"$MODES.t" && mv "$MODES.t" "$MODES"
    fi
    moved_addr=$(printf '%s\n' "$eval_args" | sed -n 's/.*address:\(0x[0-9a-fA-F]*\).*/\1/p')
    moved_mon=$(printf '%s\n' "$eval_args" | sed -n "s/.*monitor = '\\([^']*\\)'.*/\\1/p")
    if [ -n "$moved_addr" ] && [ -n "$moved_mon" ]; then
      moved_id=$(jq -R -s --arg m "$moved_mon" 'split("\n") | map(select(length>0)) | index($m)' <"$MONITORS")
      if [ "$moved_id" != "null" ]; then
        jq --arg a "$moved_addr" --argjson i "$moved_id" '. + {($a): $i}' "$CLIENT_MONITORS" >"$CLIENT_MONITORS.t" &&
          mv "$CLIENT_MONITORS.t" "$CLIENT_MONITORS"
      fi
    fi
    ;;
  reload)
    printf '{}\n' >"$MODES"
    ;;
esac
STUB
chmod +x "$TMPDIR/bin/hyprctl"

cat >"$TMPDIR/bin/gamescope" <<'GS'
#!/bin/sh
printf '%s\n' "$*" >>"$GAMESCOPE_LOG"
printf '%s' "$$" >"$GAMESCOPE_PID_FILE"
while [ $# -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
  esac
  shift
done
"$@" &
child=$!
trap 'kill "$child" 2>/dev/null; exit 143' TERM INT
while kill -0 "$child" 2>/dev/null; do
  wait "$child" 2>/dev/null || true
done
exit 139
GS
chmod +x "$TMPDIR/bin/gamescope"

export PATH="$TMPDIR/bin:$PATH"
export STREAM_GAMESCOPE="$TMPDIR/bin/gamescope"

reset_state() {
  printf 'HDMI-A-1\nDP-1\nDECK\nFRAME\n' >"$MONITORS"
  printf 'spotify\n' >"$CLIENTS"
  printf '{}\n' >"$MODES"
  printf '{}\n' >"$CLIENT_MONITORS"
  : >"$ACTIVE_WINDOW"
  rm -f "$GAMESCOPE_PID_FILE"
  : >"$HYPRCTL_LOG"
  : >"$GAMESCOPE_LOG"
  rm -f "$XDG_RUNTIME_DIR/streaming-display.lock"
}

check_round_trip() {
  local name="$1" output="$2" mode="$3"

  reset_state

  "$name" true || fail "$name must propagate a zero exit"
  grep -q "mode = \"$mode\"" "$HYPRCTL_LOG" || fail "$name never asserted its mode ($mode)"
  grep -q 'scale = 1' "$HYPRCTL_LOG" ||
    fail "$name never pinned scale explicitly (an implicit scale resolves to 2)"
  grep -q "output = \"$output\"" "$HYPRCTL_LOG" || fail "$name never referenced its own display"
  grep -q "hl.dsp.focus({ monitor = \"$output\" })" "$HYPRCTL_LOG" ||
    fail "$name never dispatched focus onto $output"
  grep -qxF "$output" "$MONITORS" || fail "$name removed its permanent display from the monitor list"

  grep -q '^output ' "$HYPRCTL_LOG" && fail "$name called hyprctl output — displays are permanent"

  reset_state
  if "$name" false; then fail "$name propagated a zero exit from a failing child"; fi
  grep -qxF "$output" "$MONITORS" || fail "$name removed its display after a failing child"

  reset_state
  printf 'HDMI-A-1\nDP-1\n' >"$MONITORS"
  if "$name" true 2>/dev/null; then
    fail "$name ran although its display was absent — it should tell the user to reload"
  fi
}

check_round_trip frame FRAME "2560x1440@120"
check_round_trip deck DECK "1280x720@90"

reset_state
deck true || fail "deck must run"
gs_args=$(cat "$GAMESCOPE_LOG")
for expected in "-w 1280" "-h 720" "-W 1280" "-H 720" "-r 90" "--keep-alive" "--mangoapp"; do
  # shellcheck disable=SC2076
  case "$gs_args" in
  *"$expected"*) ;;
  *) fail "deck did not pass '$expected' to gamescope (got: $gs_args)" ;;
  esac
done

cat >"$TMPDIR/bin/env-recorder" <<'ENVREC'
#!/bin/sh
{
  printf 'LD=%s\n' "${LD_LIBRARY_PATH-<unset>}"
  printf 'PROTON=%s\n' "${PROTON_ENABLE_WAYLAND-<unset>}"
  printf 'MANGOHUD=%s\n' "${MANGOHUD-<unset>}"
} >"$ENV_FILE"
ENVREC
chmod +x "$TMPDIR/bin/env-recorder"
export ENV_FILE="$TMPDIR/child-env"

reset_state
rm -f "$ENV_FILE"
deck "$TMPDIR/bin/env-recorder" || fail "deck must run the env recorder"
grep -qxF 'PROTON=0' "$ENV_FILE" ||
  fail "deck did not disable Proton's Wayland path for the child (got $(grep '^PROTON=' "$ENV_FILE"))"
grep -qxF 'MANGOHUD=0' "$ENV_FILE" ||
  fail "deck did not leave mangohud off for the child (got $(grep '^MANGOHUD=' "$ENV_FILE"))"
unset ENV_FILE

reset_state
frame true || fail "frame must run"
gs_args=$(cat "$GAMESCOPE_LOG")
for expected in "-w 2560" "-h 1440" "-W 2560" "-H 1440" "-r 120"; do
  # shellcheck disable=SC2076
  case "$gs_args" in
  *"$expected"*) ;;
  *) fail "frame did not pass '$expected' to gamescope (got: $gs_args)" ;;
  esac
done

reset_state
cat >"$TMPDIR/bin/exit-code" <<'EXITCODE'
#!/bin/sh
exit "$1"
EXITCODE
chmod +x "$TMPDIR/bin/exit-code"

set +e
deck "$TMPDIR/bin/exit-code" 7 >/dev/null 2>&1
rc=$?
set -e
[ "$rc" = 7 ] ||
  fail "deck did not return the child's status (got ${rc}) — gamescope's own 139 leaked through"

reset_state
deck true || fail "deck must report success for a zero-exit child despite gamescope crashing"

shadow="$TMPDIR/shadow"
mkdir -p "$shadow"
install -m 644 "$SHADOW_LIB" "$shadow/libattr.so.1"

if LD_LIBRARY_PATH="$shadow" mktemp -d >/dev/null 2>&1; then
  fail "harness no longer bites: a shadowed libattr must break mktemp"
fi

reset_state
cat >"$TMPDIR/bin/write-ld" <<'WRITELD'
#!/bin/sh
printf '%s\n' "${LD_LIBRARY_PATH-<unset>}" >"$LD_FILE"
WRITELD
chmod +x "$TMPDIR/bin/write-ld"
export LD_FILE="$TMPDIR/child-ld"

for name in frame deck; do
  reset_state
  rm -f "$LD_FILE"
  LD_LIBRARY_PATH="$shadow" "$name" "$TMPDIR/bin/write-ld" ||
    fail "$name died on a shadowed library path instead of running its own tooling"
  [ "$(cat "$LD_FILE" 2>/dev/null)" = "$shadow" ] ||
    fail "$name did not hand the child the inherited library path"
done
unset LD_FILE

reset_state
cat >"$TMPDIR/bin/hold-lock" <<'HOLDER'
#!/bin/sh
exec 9>"$XDG_RUNTIME_DIR/streaming-display.lock"
flock -n 9 || exit 1
sleep 5
HOLDER
chmod +x "$TMPDIR/bin/hold-lock"
"$TMPDIR/bin/hold-lock" &
holder=$!
sleep 0.5
if frame true 2>/dev/null; then
  fail "frame started while another streaming display held the lock"
fi
if deck true 2>/dev/null; then
  fail "deck started while another streaming display held the lock"
fi
kill "$holder" 2>/dev/null || true
wait "$holder" 2>/dev/null || true

reset_state
cat >"$TMPDIR/bin/game" <<'GAME'
#!/bin/sh
printf 'spotify\nsteam_app_0000000000\n' >"$CLIENTS"
sleep 4
printf 'spotify\n' >"$CLIENTS"
sleep 3
GAME
chmod +x "$TMPDIR/bin/game"
cat >"$TMPDIR/bin/launcher" <<'LAUNCHER'
#!/bin/sh
setsid "$TMPDIR/bin/game" >/dev/null 2>&1 &
exit 0
LAUNCHER
chmod +x "$TMPDIR/bin/launcher"

start=$(date +%s)
frame "$TMPDIR/bin/launcher" || fail "frame must propagate the launcher's zero exit"
elapsed=$(($(date +%s) - start))
[ "$elapsed" -ge 5 ] ||
  fail "frame tore down when the launcher exited instead of following the game window (${elapsed}s)"

ensures=$(grep -c 'monitors -j' "$HYPRCTL_LOG" || true)
[ "$ensures" -ge 3 ] ||
  fail "frame did not poll the display while running (${ensures} state reads)"

reset_state
deck sleep 3 &
steady_pid=$!
sleep 1
: >"$HYPRCTL_LOG"
sleep 1.5
steady_evals=$(grep -c '^eval ' "$HYPRCTL_LOG" || true)
wait "$steady_pid" 2>/dev/null || true
[ "$steady_evals" -eq 0 ] ||
  fail "ensure re-evaluated on a healthy display (${steady_evals} evals) — a healthy tick must be reads and no writes"

reset_state
printf 'HDMI-A-1\nDP-1\nDECK\n' >"$MONITORS"
deck sleep 3 &
drift_pid=$!
sleep 1
printf '{}\n' >"$MODES"
sleep 1.5
drifted_mode=$(jq -r '."DECK" // "none"' "$MODES")
wait "$drift_pid" 2>/dev/null || true
[ "$drifted_mode" = "1280x720@90" ] ||
  fail "ensure did not heal the mode after drift (got ${drifted_mode})"

reset_state
cat >"$TMPDIR/bin/mislay-games" <<'MISLAYGAMES'
#!/bin/sh
printf 'spotify\ngamescope\n' >"$CLIENTS"
printf '{"0x2": 0}\n' >"$CLIENT_MONITORS"
sleep 3
printf 'spotify\n' >"$CLIENTS"
sleep 2
MISLAYGAMES
cat >"$TMPDIR/bin/mislay" <<'MISLAY'
#!/bin/sh
setsid "$TMPDIR/bin/mislay-games" >/dev/null 2>&1 &
exit 0
MISLAY
chmod +x "$TMPDIR/bin/mislay-games" "$TMPDIR/bin/mislay"
deck "$TMPDIR/bin/mislay" || fail "deck must run with a mis-placed game window"
grep -q "address:0x2" "$HYPRCTL_LOG" ||
  fail "deck never re-placed a gamescope window that mapped onto another monitor"
grep -q "monitor = 'DECK'" "$HYPRCTL_LOG" ||
  fail "deck re-placed the game without naming its own display"

reset_state
cat >"$TMPDIR/bin/settled-games" <<'SETTLEDGAMES'
#!/bin/sh
printf 'spotify\ngamescope\n' >"$CLIENTS"
printf '{"0x2": 2}\n' >"$CLIENT_MONITORS"
sleep 4
printf 'spotify\n' >"$CLIENTS"
sleep 2
SETTLEDGAMES
cat >"$TMPDIR/bin/settled" <<'SETTLED'
#!/bin/sh
setsid "$TMPDIR/bin/settled-games" >/dev/null 2>&1 &
exit 0
SETTLED
chmod +x "$TMPDIR/bin/settled-games" "$TMPDIR/bin/settled"
deck "$TMPDIR/bin/settled" || fail "deck must run with a settled game window"
settled_moves=$(grep -c 'window.move' "$HYPRCTL_LOG" || true)
[ "$settled_moves" -eq 0 ] ||
  fail "deck re-placed an already-correct game window (${settled_moves} moves)"

reset_state
printf '0x1\n' >"$ACTIVE_WINDOW"
deck sleep 2 || fail "deck must run"
grep -q "address:0x1" "$HYPRCTL_LOG" ||
  fail "deck did not restore focus to the window that had it before launch"

reset_state
printf '0x99\n' >"$ACTIVE_WINDOW"
deck sleep 2 || fail "deck must run"
grep -q 'monitor = "HDMI-A-1"' "$HYPRCTL_LOG" ||
  fail "deck did not fall back to the remembered monitor when its window was gone"

printf 'HDMI-A-1\nDP-1\n' >"$MONITORS"
: >"$HYPRCTL_LOG"
streaming-displays
grep -q 'output create headless DECK' "$HYPRCTL_LOG" ||
  fail "streaming-displays did not create the missing DECK output"
grep -q 'output create headless FRAME' "$HYPRCTL_LOG" ||
  fail "streaming-displays did not create the missing FRAME output"
grep -q 'output = "DECK", mode = "1280x720@90"' "$HYPRCTL_LOG" ||
  fail "streaming-displays did not pin DECK's declared mode"
grep -q 'output = "FRAME", mode = "2560x1440@120"' "$HYPRCTL_LOG" ||
  fail "streaming-displays did not pin FRAME's declared mode"

printf 'HDMI-A-1\nDP-1\nDECK\nFRAME\n' >"$MONITORS"
: >"$HYPRCTL_LOG"
streaming-displays
if grep -q 'output create' "$HYPRCTL_LOG"; then
  fail "streaming-displays recreated an output that was already present"
fi
grep -q 'output = "DECK", mode = "1280x720@90"' "$HYPRCTL_LOG" ||
  fail "streaming-displays did not re-assert the declared mode of a present output"

mask() {
  sed -E -e 's|/nix/store/[a-z0-9]{32}-|/nix/store/HASH-|g' \
    -e 's/FRAME/OUT/g' -e 's/DECK/OUT/g' \
    -e 's/2560x1440@120/MODE/g' -e 's/1280x720@90/MODE/g' \
    -e 's/-w 2560 -h 1440 -W 2560 -H 1440 -r 120/GEOMETRY/g' \
    -e 's/-w 1280 -h 720 -W 1280 -H 720 -r 90/GEOMETRY/g' \
    -e 's/frame/DISPLAY/g' -e 's/deck/DISPLAY/g' "$1"
}
for tool in frame-display deck-display frame deck; do
  path=$(command -v "$tool") || fail "$tool is not on PATH"
  [ -s "$path" ] || fail "$tool resolved to nothing — the generator-equivalence diff would pass vacuously"
done

diff <(mask "$(command -v frame-display)") <(mask "$(command -v deck-display)") ||
  fail "frame-display and deck-display differ beyond their data — the generator grew a branch"

diff <(mask "$(command -v frame)") <(mask "$(command -v deck)") ||
  fail "frame and deck differ beyond their data — the generator grew a branch"

echo "streaming: all assertions hold"
