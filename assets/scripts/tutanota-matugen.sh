#!/usr/bin/env bash

set -euo pipefail
umask 077

fail() {
  printf '%s\n' "tutanota-matugen: $1; configuration left unchanged" >&2
  exit 1
}

mode=${1:---apply}
shift "$(($# > 0 ? 1 : 0))"
case "$mode" in
--apply | --publish) [[ $# == 0 ]] || fail 'unexpected arguments' ;;
--launch) ;;
*) fail 'unknown mode' ;;
esac

cache=${XDG_CACHE_HOME:-$HOME/.cache}/tutanota-matugen
conf=${XDG_CONFIG_HOME:-$HOME/.config}/tutanota-desktop/conf.json
palette=$cache/theme.json
mkdir -p -- "$cache"
temps=()
cleanup() {
  if ((${#temps[@]})); then rm -f -- "${temps[@]}"; fi
}
trap cleanup EXIT

valid_palette() {
  jq -e -s --argjson keys "$TUTA_THEME_KEYS" '
    length == 1 and (.[0] |
      type == "object" and (keys == $keys) and .themeId == "matugen" and
      (.logo | type == "string" and startswith("<svg")) and
      (del(.themeId, .logo) | all(.[]; type == "string" and test("^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$"))))
  ' "$1" >/dev/null 2>&1
}

if [[ $mode == --publish ]]; then
  [[ -f $palette.tmp && ! -L $palette.tmp ]] || fail 'rendered palette missing'
  published=$(mktemp "$cache/.theme.XXXXXX")
  temps+=("$published")
  cp -- "$palette.tmp" "$published"
  valid_palette "$published" || fail 'invalid rendered palette'
  chmod 600 -- "$published"
  mv -fT -- "$published" "$palette"
  rm -f -- "$palette.tmp"
fi

exec 9>"$cache/apply.lock"
if flock -n -E 200 9; then
  :
else
  lock_status=$?
  [[ $lock_status == 200 ]] || fail 'cannot lock app configuration'
  if [[ $mode == --launch ]]; then exec "$TUTA_EXECUTABLE" "$@"; fi
  exit 0
fi

app_running() {
  local status
  if pgrep -u "$(id -u)" -x 'tutanota-deskto' >/dev/null; then return 0; else status=$?; fi
  [[ $status == 1 ]] || fail 'cannot check app processes'
  return 1
}

apply_theme() {
  [[ -e $palette ]] || return 0
  [[ -f $palette && ! -L $palette ]] || fail 'invalid palette file'
  [[ -e $conf ]] || return 0
  [[ -f $conf && ! -L $conf ]] || fail 'invalid app configuration file'
  if app_running; then return 0; fi
  local snapshot theme merged backup
  snapshot=$(mktemp "${conf%/*}/.conf-original.XXXXXX")
  temps+=("$snapshot")
  theme=$(mktemp "$cache/.theme-input.XXXXXX")
  temps+=("$theme")
  merged=$(mktemp "${conf%/*}/.conf-matugen.XXXXXX")
  temps+=("$merged")
  cp -- "$conf" "$snapshot"
  cp -- "$palette" "$theme"
  valid_palette "$theme" || fail 'invalid palette'
  jq -e -s '
    length == 1 and (.[0] | type == "object" and
      ((has("themes") | not) or (.themes | type == "array" and all(.[]; type == "object" and (.themeId | type == "string")))) and
      ((has("selectedTheme") | not) or (.selectedTheme | type == "string")))
  ' "$snapshot" >/dev/null 2>&1 || fail 'invalid app configuration'
  jq --slurpfile theme "$theme" '
    (any(.themes[]?; .themeId == "matugen")) as $installed |
    .themes = ([.themes[]? | select(.themeId != "matugen")] + $theme) |
    if $installed then . else .selectedTheme = "matugen" end
  ' "$snapshot" >"$merged" 2>/dev/null || fail 'theme merge failed'
  jq -e 'type == "object" and ([.themes[] | select(.themeId == "matugen")] | length == 1)' "$merged" >/dev/null 2>&1 || fail 'invalid merged configuration'
  if jq -e --slurpfile merged "$merged" '. == $merged[0]' "$snapshot" >/dev/null; then return 0; fi
  if app_running; then return 0; fi
  cmp -s -- "$snapshot" "$conf" || fail 'app configuration changed during merge'
  backup=$conf.pre-matugen
  if [[ ! -e $backup && ! -L $backup ]]; then
    (
      set -o noclobber
      cat -- "$snapshot" >"$backup"
    ) || fail 'backup failed'
  fi
  [[ -f $backup && ! -L $backup ]] || fail 'invalid backup file'
  chmod 600 -- "$backup" "$merged"
  if app_running; then return 0; fi
  cmp -s -- "$snapshot" "$conf" || fail 'app configuration changed during backup'
  mv -fT -- "$merged" "$conf"
}

if [[ $mode == --launch ]]; then
  apply_theme
  cleanup
  temps=()
  "$TUTA_EXECUTABLE" "$@" &
  child=$!
  trap 'kill -TERM "$child" 2>/dev/null || true' TERM
  trap 'kill -INT "$child" 2>/dev/null || true' INT
  status=0
  wait "$child" || status=$?
  exit "$status"
fi
apply_theme
