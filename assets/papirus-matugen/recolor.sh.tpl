# Papirus matugen recolor — rendered by matugen (palette injected), run
# asynchronously by the papirus-matugen.path unit.
# Ships one child theme Papirus-Matugen-Dark inheriting Papirus-Dark: every
# reachable places/ dir exists locally (mostly symlinks); the ~80 files per
# size that carry the stock blue anchor colors are rewritten with the live
# Material palette. gtk-update-icon-cache is refreshed at the end.
set -eu

papirus_root="@PAPIRUS_ICONS@"
cache_tool="@GTK_CACHE@"
accent="{{colors.primary.default.hex}}"
tone="{{colors.primary.default.hex | set_lightness: 73.0}}"
accent="${accent#\#}"
tone="${tone#\#}"

parent="Papirus-Dark"
child="Papirus-Matugen-Dark"
out_root="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
tmp="$out_root/.papirus-matugen.tmp.$$"

trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp"

src="$papirus_root/$parent"
dst="$tmp/$child"
mkdir -p "$dst"

sed -e "s|^Name=.*|Name=$child|" \
    -e "s|^Inherits=.*|Inherits=$parent,breeze-dark,hicolor|" \
    "$src/index.theme" > "$dst/index.theme"

while IFS= read -r -d '' places; do
  rel="${places#"$src/"}"
  mkdir -p "$dst/$rel"

  anchored="$(grep -rl "5294e2\|4877b1" "$places" | xargs -r -n1 basename | tr '\n' ' ')"

  for entry in "$places"/*; do
    name="$(basename "$entry")"
    target="$dst/$rel/$name"

    needs_render=0
    case " $anchored " in *" $name "*) needs_render=1 ;; esac
    if [ "$needs_render" = 0 ] && [ -L "$entry" ]; then
      resolved="$(realpath "$entry")"
      case " $anchored " in *" $(basename "$resolved") "*) needs_render=1 ;; esac
    fi

    if [ "$needs_render" = 1 ]; then
      sed -e "s|5294e2|$accent|Ig" -e "s|4877b1|$tone|Ig" "$entry" > "$target"
    else
      ln -s "$(realpath "$entry")" "$target"
    fi
  done
done < <(find -L "$src" -type d -name places -print0)

"$cache_tool" -q -f "$dst"

rm -rf "$out_root/$child"
mv "$tmp/$child" "$out_root/$child"
