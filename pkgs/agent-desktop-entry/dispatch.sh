#!/usr/bin/env bash
set -u

unit='@outerUnit@'
runtime='@runtimeDirectory@'
home='@homeDirectory@'
request=$1
term=$2

ready() {
  local invocation receipt receipt_owner receipt_mode directory_owner directory_mode
  invocation=$('@systemctlPath@' --system --no-ask-password show --property=InvocationID --value -- "$unit") || return 1
  [[ $invocation =~ ^[0-9a-f]{32}$ ]] || return 1
  '@systemctlPath@' --system --no-ask-password is-active --quiet -- "$unit" || return 1
  [[ -d $runtime && ! -L $runtime && -f $runtime/ready && ! -L $runtime/ready && -S $runtime/bus && ! -L $runtime/bus ]] || return 1
  read -r directory_owner directory_mode < <('@statPath@' -c '%u %a' -- "$runtime") || return 1
  read -r receipt_owner receipt_mode < <('@statPath@' -c '%u %a' -- "$runtime/ready") || return 1
  [[ $directory_owner == 0 && $receipt_owner == 0 && $directory_mode =~ ^[0-7]{3,4}$ && $receipt_mode =~ ^[0-7]{3,4}$ ]] || return 1
  (((8#$directory_mode & 8#022) == 0 && (8#$receipt_mode & 8#022) == 0)) || return 1
  if IFS= read -r -d '' -n 34 receipt <"$runtime/ready"; then
    return 1
  fi
  [[ $receipt == "$invocation" || $receipt == "$invocation"$'\n' ]]
}

case $request in
'agent-desktop start')
  '@systemctlPath@' --system --no-ask-password start -- "$unit" || exit $?
  ready || {
    printf '%s\n' 'desktop not ready' >&2
    exit 1
  }
  exit 0
  ;;
'agent-desktop status')
  '@systemctlPath@' --system --no-ask-password show --property=ActiveState --property=SubState --property=InvocationID -- "$unit"
  exit $?
  ;;
'agent-desktop stop')
  '@systemctlPath@' --system --no-ask-password stop -- "$unit"
  exit $?
  ;;
esac

ready || {
  printf '%s\n' 'desktop not ready' >&2
  exit 1
}
export XDG_RUNTIME_DIR="$runtime"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus"
args=(--user --wait --collect --quiet --service-type=exec --slice=app.slice --expand-environment=no --property="WorkingDirectory=$home")
if [[ -t 0 && -t 1 ]]; then
  args+=(--pty)
else
  args+=(--pipe)
fi
if [[ $term =~ ^[A-Za-z0-9_.+-]{1,128}$ ]]; then
  args+=(--setenv="TERM=$term")
fi
if [[ -z $request ]]; then
  exec '@systemdRunPath@' "${args[@]}" -- '@bashPath@' --noprofile --norc -i
else
  exec '@systemdRunPath@' "${args[@]}" -- '@bashPath@' --noprofile --norc -c "$request"
fi
