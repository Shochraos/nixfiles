#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

theme=$(command -v theme-sync) || fail "theme-sync is not on PATH"
name=$(grep -oE 'spicetify-[A-Za-z0-9]+\.json' "$theme" | head -1)
[ -n "$name" ] || fail "cannot derive the theme file name out of theme-sync"

repo="$TMPDIR/repo"
git init -q "$repo"
export THEME_SYNC_REPO="$repo"
src="$HOME/.local/state/matugen/$name"
dst="$repo/configs/matugen/$name"
mkdir -p "$(dirname "$src")" "$repo/configs/matugen"

out=$(theme-sync)
[ ! -e "$dst" ] || fail "theme-sync wrote $dst with no source present"
[ -z "$out" ] || fail "theme-sync should stay silent without a source: $out"

printf '{ "accent": "zzzzzz" }\n' >"$src"
printf 'PREVIOUS\n' >"$dst"
out=$(theme-sync 2>"$TMPDIR/err")
grep -q 'incomplete or malformed, keeping current theme' "$TMPDIR/err" ||
  fail "a malformed theme was not reported: $(cat "$TMPDIR/err")"
[ "$(cat "$dst")" = "PREVIOUS" ] ||
  fail "a malformed theme replaced the current one: $(cat "$dst")"
[ -z "$out" ] || fail "a malformed theme should not report an update: $out"

rm -f "$dst"
printf '{ "primary": "112233", "secondary": "445566" }\n' >"$src"
out=$(theme-sync)
[ -e "$dst" ] || fail "a valid theme was not copied to $dst"
grep -q 'theme-sync: updated' <<<"$out" || fail "no update reported: $out"
staged=$(git -C "$repo" status --porcelain -- "configs/matugen/$name")
[ -n "$staged" ] || fail "the new theme file was not brought into the repo"
git -C "$repo" ls-files --error-unmatch "configs/matugen/$name" >/dev/null 2>&1 ||
  fail "the new theme file is not in the index: $staged"

out=$(theme-sync)
[ -z "$out" ] || fail "an unchanged theme was copied again: $out"

printf '{ "primary": "778899", "secondary": "445566" }\n' >"$src"
out=$(theme-sync)
grep -q 'theme-sync: updated' <<<"$out" || fail "a changed theme was not copied: $out"
grep -q '778899' "$dst" || fail "the changed theme did not reach $dst"

echo "theme-sync: all assertions hold"
