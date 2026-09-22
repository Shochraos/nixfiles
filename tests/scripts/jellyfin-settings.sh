#!/usr/bin/env bash
set -euo pipefail

export XDG_CONFIG_HOME="$TMPDIR/config"
settings="$XDG_CONFIG_HOME/jellyfin-mpv-shim/conf.json"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

value() { jq -r "$1" "$settings"; }

jellyfin-settings >"$TMPDIR/out" 2>"$TMPDIR/err" || {
  cat "$TMPDIR/err" >&2
  fail "jellyfin-settings failed with no config file present"
}
[ -f "$settings" ] || fail "an absent config was not created"
grep -q 'created' "$TMPDIR/out" || fail "creating the config was not reported"
[ "$(value '.start_minimized')" = "true" ] || fail "the created config does not start minimized"
[ "$(value '.mpv_ext')" = "true" ] || fail "the created config does not use the external mpv"

cat >"$settings" <<'JSON'
{
  "client_uuid": "00000000-0000-0000-0000-000000000000",
  "window_width": 1234,
  "osc_style": "mpvtk",
  "start_minimized": false,
  "language_config": [
    {
      "type": "sub",
      "slang": "eng"
    }
  ]
}
JSON

jellyfin-settings >"$TMPDIR/out" 2>"$TMPDIR/err" || {
  cat "$TMPDIR/err" >&2
  fail "jellyfin-settings failed on an existing config"
}
[ "$(value '.client_uuid')" = "da0d3218-d79c-426b-ae6d-1857bcfc5833" ] ||
  fail "the merged config did not take the pinned client_uuid"
[ "$(value '.start_minimized')" = "true" ] ||
  fail "the merged config did not take start_minimized"
[ "$(value '.osc_style')" = "custom" ] ||
  fail "the merged config overrode a stale osc_style with the wrong style"
[ "$(value '.window_width')" = "1234" ] ||
  fail "the merge dropped a key only the app sets"
[ "$(value '.language_config[0].slang')" = "eng" ] ||
  fail "the merge dropped a nested key only the app sets"

before=$(stat -c '%y' "$settings")
sleep 1
jellyfin-settings >"$TMPDIR/out" 2>"$TMPDIR/err" || fail "a repeated run failed"
[ "$(stat -c '%y' "$settings")" = "$before" ] ||
  fail "a run with nothing to change rewrote the config anyway"

chmod 640 "$settings"
jq '.start_minimized = false' "$settings" >"$settings.stale"
mv "$settings.stale" "$settings"
chmod 640 "$settings"
jellyfin-settings >/dev/null 2>&1 || fail "a run on a 0640 config failed"
[ "$(stat -c '%a' "$settings")" = "640" ] || fail "the merge changed the config's mode"

printf 'not json\n' >"$settings"
before=$(md5sum "$settings")
if ! jellyfin-settings >/dev/null 2>"$TMPDIR/err"; then
  fail "an unreadable config made jellyfin-settings exit non-zero"
fi
grep -q 'not valid JSON' "$TMPDIR/err" || fail "an unreadable config was not reported"
[ "$(md5sum "$settings")" = "$before" ] || fail "an unreadable config was overwritten"

echo "jellyfin-settings: all assertions hold"
