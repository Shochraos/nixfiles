#!/usr/bin/env bash
set -euo pipefail

prog=${0##*/}

die() {
  printf '%s: error: %s\n' "$prog" "$1" >&2
  exit 2
}

proc_start() {
  local pid=$1 stat rest start
  local -a fields
  stat=
  { IFS= read -r -d '' stat <"/proc/$pid/stat"; } 2>/dev/null || true
  [[ -n $stat ]] || return 1
  [[ $stat == *')'* ]] || return 1
  rest=${stat##*')'}
  read -r -a fields <<<"$rest"
  [[ ${fields[0]-} != Z ]] || return 1
  start=${fields[19]-}
  [[ -n $start ]] || return 1
  printf '%s' "$start"
}

output=
have_output=false
positionals=()

while (($#)); do
  case $1 in
  -h | --help)
    printf 'usage: %s --output OUTPUT {on,off,refresh} [owner] [pid]\n' "$prog"
    exit 0
    ;;
  --output)
    (($# >= 2)) || die "argument --output: expected one argument"
    output=$2
    have_output=true
    shift 2
    ;;
  --output=*)
    output=${1#*=}
    have_output=true
    shift
    ;;
  --)
    shift
    positionals+=("$@")
    break
    ;;
  -*)
    die "unrecognized arguments: $1"
    ;;
  *)
    positionals+=("$1")
    shift
    ;;
  esac
done

[[ $have_output == true ]] || die "the following arguments are required: --output"
((${#positionals[@]} >= 1)) || die "the following arguments are required: action"
((${#positionals[@]} <= 3)) || die "unrecognized arguments: ${positionals[*]:3}"
action=${positionals[0]}
owner=${positionals[1]-manual}
pid=${positionals[2]-}

case $action in
on | off | refresh) ;;
*) die "argument action: invalid choice: '$action' (choose from 'on', 'off', 'refresh')" ;;
esac

[[ $owner =~ ^[A-Za-z0-9_-]+$ ]] || die "owner must contain only letters, digits, underscores or hyphens"
if ((${#positionals[@]} == 3)); then
  [[ $pid =~ ^[-+]?[0-9]+$ ]] || die "argument pid: invalid int value: '$pid'"
fi

runtime=${XDG_RUNTIME_DIR-}
[[ -n $runtime ]] || die "XDG_RUNTIME_DIR is required"

directory=$runtime/nixfiles-hdr
mkdir -p -- "$runtime"
if [[ ! -d $directory ]]; then
  mkdir -p -- "$directory" && chmod 700 -- "$directory"
fi
exec {lock_fd}>>"$directory/lock"
flock -x "$lock_fd"

state=$directory/owners.json
overlay=$directory/state.lua
pending=$directory/reload-pending
tmp_state=
tmp_lua=
tmp_err=
tmp_input=

trap 'rm -f -- "$tmp_state" "$tmp_lua" "$tmp_err" "$tmp_input"' EXIT

tmp_err=$(mktemp --tmpdir="$directory" hdr-err.XXXXXX)

input=$state
if [[ ! -e $state ]]; then
  tmp_input=$(mktemp --tmpdir="$directory" hdr-input.XXXXXX)
  printf '{}\n' >"$tmp_input"
  input=$tmp_input
fi

validate='def valid: if . == null then true elif type == "object" then ((.pid | type) == "number") and ((.start | type) == "string") else false end; type == "object" and (to_entries | all(.value | valid))'
if ! jq -e -s "length == 1 and (.[0] | $validate)" "$input" >/dev/null 2>"$tmp_err"; then
  detail=$(tr '\n' ' ' <"$tmp_err")
  [[ -n $detail ]] || detail="expected an object of null or pid/start leases"
  printf '%s: cannot read %s: %s\n' "$prog" "$state" "$detail" >&2
  exit 1
fi

entries=()
while IFS=$'\t' read -r key record_pid record_start; do
  [[ -n $key ]] || continue
  [[ $key != "$owner" || $action == refresh ]] || continue
  if [[ -n $record_pid ]]; then
    start=$(proc_start "$record_pid") || continue
    [[ $start == "$record_start" ]] || continue
  fi
  entries+=("$key"$'\t'"$record_pid"$'\t'"$record_start")
done < <(jq -r 'to_entries[] | [.key, (.value.pid // ""), (.value.start // "")] | @tsv' "$input")

if [[ $action == on ]]; then
  if [[ -n $pid ]]; then
    start=$(proc_start "$pid") || die "owner process is not alive"
    entries+=("$owner"$'\t'"$pid"$'\t'"$start")
  else
    entries+=("$owner"$'\t\t')
  fi
fi

tmp_state=$(mktemp --tmpdir="$directory" hdr-state.XXXXXX)
if ((${#entries[@]})); then
  printf '%s' "${entries[@]/%/$'\n'}" |
    jq -Rn '[inputs | split("\t") | {key: .[0], value: (if .[1] == "" then null else {pid: (.[1] | tonumber), start: .[2]} end)}] | from_entries' -S -c -j >"$tmp_state"
else
  printf '{}' >"$tmp_state"
fi
mv -f -T -- "$tmp_state" "$state"
tmp_state=

tmp_lua=$(mktemp --tmpdir="$directory" hdr-lua.XXXXXX)
if ((${#entries[@]})); then
  printf '%s' "$output" | jq -Rsrj '"hl.monitor({ output = " + (tojson) + ", cm = \"hdredid\" })\n"' >"$tmp_lua"
else
  : >"$tmp_lua"
fi

same=false
if [[ -e $overlay ]]; then
  if cmp -s -- "$overlay" "$tmp_lua"; then
    same=true
  fi
elif [[ ! -s $tmp_lua ]]; then
  same=true
fi
if [[ $same == false ]]; then
  touch -- "$pending"
fi
if [[ $same == false || ! -e $overlay ]]; then
  mv -f -T -- "$tmp_lua" "$overlay"
  tmp_lua=
fi

if [[ -e $pending ]]; then
  hyprctl=${HDR_HYPRCTL:-hyprctl}
  status=0
  "$hyprctl" reload >/dev/null 2>"$tmp_err" {lock_fd}>&- || status=$?
  if ((status != 0)); then
    if [[ -s $tmp_err ]]; then
      cat -- "$tmp_err" >&2
    else
      printf 'hyprctl reload failed\n' >&2
    fi
    exit "$status"
  fi
  rm -f -- "$pending"
fi

exit 0
