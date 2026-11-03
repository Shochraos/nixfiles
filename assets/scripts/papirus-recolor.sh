#!/usr/bin/env bash
set -euo pipefail

cache="$PAPIRUS_CACHE"
out_root="$PAPIRUS_OUTPUT"
parent=Papirus-Dark
child=Papirus-Matugen-Dark
renderer_format_version=1
mkdir -p "$cache"
if [[ ${1:-} != --publish ]]; then
  exec 9>"$cache/recolor.lock"
  flock 9
fi
exec 8>"$cache/palette.lock"
flock 8

read_palette() {
  local file="$1"
  local -a colors=()
  [[ -f $file ]] || return 1
  mapfile -t -n 3 colors <"$file"
  [[ ${#colors[@]} == 2 ]] || return 1
  [[ ${colors[0]} =~ ^#[[:xdigit:]]{6}$ && ${colors[1]} =~ ^#[[:xdigit:]]{6}$ ]] || return 1
  accent="${colors[0]#\#}"
  tone="${colors[1]#\#}"
  accent="${accent,,}"
  tone="${tone,,}"
}

publish_palette() {
  local palette_tmp
  palette_tmp="$(mktemp "$cache/.palette.XXXXXXXX")"
  printf '#%s\n#%s\n' "$accent" "$tone" >"$palette_tmp"
  mv -fT -- "$palette_tmp" "$cache/palette.txt"
}

case "${1:-}" in
--publish)
  read_palette "$cache/palette.txt.tmp" || exit 1
  publish_palette
  rm -f -- "$cache/palette.txt.tmp"
  exit 0
  ;;
"") ;;
*) exit 2 ;;
esac

if ! read_palette "$cache/palette.txt"; then
  accent=5294e2
  tone=4877b1
  if [[ ! -e "$cache/palette.txt" && -f "$cache/recolor.sh" ]]; then
    legacy_accent="$(sed -nE 's/^accent="(#[[:xdigit:]]{6})"$/\1/p' "$cache/recolor.sh")"
    legacy_tone="$(sed -nE 's/^tone="(#[[:xdigit:]]{6})"$/\1/p' "$cache/recolor.sh")"
    if [[ $legacy_accent =~ ^#[[:xdigit:]]{6}$ && $legacy_tone =~ ^#[[:xdigit:]]{6}$ ]]; then
      accent="${legacy_accent#\#}"
      tone="${legacy_tone#\#}"
      accent="${accent,,}"
      tone="${tone,,}"
      publish_palette
    fi
  fi
fi
flock -u 8
exec 8>&-

mkdir -p "$out_root"
work="$(mktemp -d "$out_root/.papirus-matugen.XXXXXXXX")"
old_output=
cleanup() {
  local status=$?
  if [[ $(readlink -- "$out_root/$child" || true) != "$work/$child" ]]; then
    rm -rf -- "$work"
  else
    rm -rf -- "$work/next"
  fi
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf '%s\n' "$PAPIRUS_ROOT" "$GTK_CACHE" "$renderer_format_version" "$accent" "$tone" >"$work/inputs"
if [[ -r "$out_root/$child/index.theme" && -r "$out_root/$child/.inputs" ]] &&
  [[ $(<"$work/inputs") == $(<"$out_root/$child/.inputs") ]]; then
  rm -f -- "$cache/recolor.sh" "$cache/recolor.sh.tmp"
  exit 0
fi

src="$PAPIRUS_ROOT/$parent"
dst="$work/$child"
mkdir -p "$dst"
sed -e "s|^Name=.*|Name=$child|" \
  -e "s|^Inherits=.*|Inherits=$parent,breeze-dark,hicolor|" \
  "$src/index.theme" >"$dst/index.theme"

find -L "$src" -type d -name places -print0 >"$work/places"
while IFS= read -r -d '' places; do
  rel="${places#"$src/"}"
  mkdir -p "$dst/$rel"
  for entry in "$places"/*; do
    [[ -e $entry ]] || continue
    name="${entry##*/}"
    target="$dst/$rel/$name"
    if grep -qiE '5294e2|4877b1' "$entry"; then
      sed -e "s|5294e2|$accent|Ig" -e "s|4877b1|$tone|Ig" "$entry" >"$target"
    else
      ln -s "$(realpath -e "$entry")" "$target"
    fi
  done
done <"$work/places"

"$GTK_CACHE" -q -f "$dst"
mv -- "$work/inputs" "$dst/.inputs"
rm -f -- "$work/places"
ln -s -- "$dst" "$work/next"
if [[ -L "$out_root/$child" ]]; then
  old_output="$(readlink -- "$out_root/$child")"
  mv -fT -- "$work/next" "$out_root/$child"
elif [[ -e "$out_root/$child" ]]; then
  mv --exchange --no-copy -T -- "$work/next" "$out_root/$child"
else
  mv -T -- "$work/next" "$out_root/$child"
fi
case "$old_output" in
"$out_root"/.papirus-matugen.????????/"$child")
  if [[ -f "$old_output/.inputs" && ! -L ${old_output%/*} ]]; then
    rm -rf -- "${old_output%/*}"
  fi
  ;;
esac
rm -f -- "$cache/recolor.sh" "$cache/recolor.sh.tmp"
