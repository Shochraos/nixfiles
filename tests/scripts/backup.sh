#!/usr/bin/env bash
set -euo pipefail

state="$TMPDIR/borg-state"
mkdir -p "$state" "$TMPDIR/bin"
export STATE="$state"

archive="Azazel-backup-2026-09-20T03:30:00"
other="Azazel-backup-2026-09-19T15:24:28"
root="$XDG_RUNTIME_DIR/borg"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cat >"$TMPDIR/bin/borg" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$BORG_LOG"
case "$1" in
  list) printf '%s\n' "${STUB_ARCHIVE-}" ;;
  mount)
    [ -z "${STUB_MOUNT_FAIL-}" ] || {
      echo "stub: mount refused" >&2
      exit 2
    }
    printf '%s\n' "$3" >"$STATE/$(basename "$3")"
    mkdir -p "$3/mnt/nextcloud/Security/KeePass"
    printf 'vault\n' >"$3/mnt/nextcloud/Security/KeePass/Vault.kdbx"
    ;;
  umount)
    [ -z "${STUB_BUSY-}" ] || {
      echo "fusermount: failed to unmount $2: Device or resource busy" >&2
      exit 1
    }
    rm -rf "$2/mnt"
    rm -f "$STATE/$(basename "$2")"
    ;;
esac
STUB
chmod +x "$TMPDIR/bin/borg"

cat >"$TMPDIR/bin/findmnt" <<'STUB'
#!/bin/sh
for f in "$STATE"/*; do
  [ -e "$f" ] || continue
  printf 'borgfs %s\n' "$(cat "$f")"
done
STUB
chmod +x "$TMPDIR/bin/findmnt"

export BORG_LOG="$TMPDIR/borg.log" PATH="$TMPDIR/bin:$PATH"
export STUB_ARCHIVE="$archive"
: >"$BORG_LOG"

case "$(command -v borg)" in
"$TMPDIR"/bin/borg) ;;
*) fail "harness is not exercising the stub borg" ;;
esac

grep -qF 'mnt/nextcloud/Security' "$(command -v backup)" ||
  fail "backup does not carry the host's archived root"

if STUB_ARCHIVE="" backup mount >/dev/null 2>"$TMPDIR/err"; then
  fail "mount with no archive available exited 0"
fi
grep -q 'no archive' "$TMPDIR/err" || fail "the no-archive failure did not explain itself"

out=$(backup mount)
first=$(printf '%s\n' "$out" | head -n 1)
[ "$first" = "$root/$archive" ] || fail "mount printed '$first' instead of the mountpoint"
printf '%s\n' "$out" | grep -qF 'KeePass' || fail "mount did not list the archived root"
[ -f "$root/$archive/mnt/nextcloud/Security/KeePass/Vault.kdbx" ] ||
  fail "the archived tree is not visible at the mountpoint"
grep -qxF "mount ::$archive $root/$archive" "$BORG_LOG" ||
  fail "mount did not borg-mount the newest archive"

: >"$BORG_LOG"
backup mount >/dev/null
if grep -q '^mount ' "$BORG_LOG"; then
  fail "a second mount re-mounted instead of reporting the existing mount"
fi

: >"$BORG_LOG"
backup mount "$other" >/dev/null
grep -qxF "mount ::$other $root/$other" "$BORG_LOG" ||
  fail "an explicit archive name was not honoured"

: >"$BORG_LOG"
backup unmount >/dev/null
[ "$(grep -c '^umount ' "$BORG_LOG")" = 2 ] || fail "unmount did not unmount both mounts"
[ -z "$("$TMPDIR/bin/findmnt")" ] || fail "unmount left mounts behind"
if [ -e "$root" ]; then fail "unmount left the mount root behind"; fi

backup unmount >"$TMPDIR/out" || fail "unmount with nothing mounted must exit 0"
grep -q 'nothing mounted' "$TMPDIR/out" || fail "unmount with nothing mounted did not say so"

backup mount >/dev/null
if STUB_BUSY=1 backup unmount >/dev/null 2>"$TMPDIR/err"; then
  fail "a busy unmount exited 0"
fi
grep -q 'busy' "$TMPDIR/err" || fail "a busy unmount did not explain the failure"
grep -qF "$root/$archive" "$TMPDIR/err" || fail "a busy unmount did not name the mount"
[ -n "$("$TMPDIR/bin/findmnt")" ] || fail "a busy unmount dropped the mount anyway"

backup unmount >/dev/null || fail "unmount failed once the holder was gone"

if backup wibble >/dev/null 2>"$TMPDIR/err"; then
  fail "an unknown verb exited 0"
fi
grep -q 'usage: backup' "$TMPDIR/err" || fail "an unknown verb did not print usage"

echo "backup: all assertions hold"
