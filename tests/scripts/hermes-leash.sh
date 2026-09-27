#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

wrapper=$(command -v hermes) || fail "hermes is not on PATH"
grep -q 'HERMES_LEASH_CHILD' "$wrapper" ||
  fail "the hermes on PATH is not the leash wrapper: $wrapper"

work="$TMPDIR/stubs"
mkdir -p "$work"

cat >"$work/stub-rc.sh" <<'EOF'
#!/bin/sh
printf 'ARGS:%s\n' "$*" >"$MARKER"
exit 7
EOF

cat >"$work/stub-ok.sh" <<'EOF'
#!/bin/sh
exit 0
EOF

cat >"$work/stub-stubborn.sh" <<'EOF'
#!/bin/sh
trap '' TERM
echo $$ >"$PIDFILE"
while :; do sleep 1; done
EOF

cat >"$work/stub-int.sh" <<'EOF'
#!/bin/sh
sleep 30 &
sleeper=$!
trap 'kill "$sleeper" 2>/dev/null || true; echo INT-SEEN >"$MARKER"; exit 42' INT
echo $$ >"$PIDFILE"
wait "$sleeper" || true
exit 0
EOF

chmod +x "$work"/*.sh

export MARKER="$TMPDIR/marker"
export PIDFILE="$TMPDIR/pidfile"

rm -f "$MARKER"
rc=0
HERMES_LEASH_CHILD="$work/stub-rc.sh" "$wrapper" alpha 'beta gamma' || rc=$?
[ "$rc" -eq 7 ] || fail "a child exiting 7 must exit the wrapper with 7, got $rc"
grep -qxF 'ARGS:alpha beta gamma' "$MARKER" ||
  fail "arguments were not forwarded: $(cat "$MARKER")"

rc=0
HERMES_LEASH_CHILD="$work/stub-ok.sh" "$wrapper" || rc=$?
[ "$rc" -eq 0 ] || fail "a clean child exit must stay 0, got $rc"

rm -f "$PIDFILE"
HERMES_LEASH_CHILD="$work/stub-stubborn.sh" "$wrapper" &
wpid=$!
for _ in $(seq 30); do
  [ -s "$PIDFILE" ] && break
  sleep 0.1
done
[ -s "$PIDFILE" ] || fail "the stubborn stub never started"
child=$(cat "$PIDFILE")
started=$(date +%s)
kill -TERM "$wpid"
while kill -0 "$wpid" 2>/dev/null; do
  [ "$(($(date +%s) - started))" -lt 8 ] || {
    kill -KILL "$wpid" "$child" 2>/dev/null || true
    fail "the wrapper did not exit within 8s of SIGTERM"
  }
  sleep 0.1
done
rc=0
wait "$wpid" || rc=$?
[ "$rc" -eq 143 ] || fail "a TERM-leashed run must exit 143, got $rc"
kill -0 "$child" 2>/dev/null &&
  fail "the leash left a SIGTERM-ignoring child alive (pid $child)"

rm -f "$MARKER" "$PIDFILE"
HERMES_LEASH_CHILD="$work/stub-int.sh" env --default-signal=INT "$wrapper" &
wpid=$!
for _ in $(seq 30); do
  [ -s "$PIDFILE" ] && break
  sleep 0.1
done
[ -s "$PIDFILE" ] || fail "the SIGINT stub never started"
child=$(cat "$PIDFILE")
kill -INT "$wpid" "$child"
rc=0
wait "$wpid" || rc=$?
[ -f "$MARKER" ] ||
  fail "SIGINT never reached the child as a catchable signal (SIG_IGN leak from the wrapper?)"
grep -qxF 'INT-SEEN' "$MARKER" ||
  fail "the child did not handle SIGINT: $(cat "$MARKER")"
[ "$rc" -eq 42 ] ||
  fail "the wrapper must propagate the child's status after SIGINT, got $rc"

echo "hermes-leash: all assertions hold"
