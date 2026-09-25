#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

command -v steamvr-facet-renderer >/dev/null || fail "steamvr-facet-renderer is not on PATH"
settings="$TMPDIR/steamvr.vrsettings"
export STEAMVR_SETTINGS="$settings"

if [ -e "$settings" ]; then fail "$settings should start absent"; fi
steamvr-facet-renderer || fail "a missing settings file must exit 0"
[ ! -e "$settings" ] || fail "no settings file should be created"

printf '{}\n' >"$settings"
steamvr-facet-renderer || fail "merging into an empty file must exit 0"
jq -e '.steamvr.useFacetRenderer == true' "$settings" >/dev/null ||
  fail "the facet renderer key was not set: $(cat "$settings")"

printf '{ "steamvr": { "installID": "abc", "useFacetRenderer": false }, "power": { "autoSpawn": true } }\n' >"$settings"
chmod 640 "$settings"
cp "$settings" "$TMPDIR/before"
steamvr-facet-renderer || fail "merging must exit 0"
jq -e '.steamvr.useFacetRenderer == true' "$settings" >/dev/null ||
  fail "the facet renderer key was not set: $(cat "$settings")"
jq -e '.steamvr.installID == "abc"' "$settings" >/dev/null ||
  fail "a key only the app sets was dropped: $(cat "$settings")"
jq -e '.power.autoSpawn == true' "$settings" >/dev/null ||
  fail "a nested section outside steamvr was dropped: $(cat "$settings")"
mode=$(stat -c '%a' "$settings")
[ "$mode" = 640 ] || fail "the merge changed the config's mode to $mode"

cp "$settings" "$TMPDIR/merged"
steamvr-facet-renderer || fail "an already-set file must exit 0"
cmp -s "$TMPDIR/merged" "$settings" || fail "an already-set file was rewritten"

printf '{ not json\n' >"$settings"
cp "$settings" "$TMPDIR/broken"
steamvr-facet-renderer 2>"$TMPDIR/err" || fail "invalid JSON must exit 0"
grep -q 'not valid JSON, leaving it untouched' "$TMPDIR/err" ||
  fail "invalid JSON was not reported: $(cat "$TMPDIR/err")"
cmp -s "$TMPDIR/broken" "$settings" || fail "invalid JSON was modified"

echo "steamvr-facet-renderer: all assertions hold"
