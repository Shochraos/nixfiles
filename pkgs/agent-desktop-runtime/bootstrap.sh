#!/usr/bin/env bash
set -eu

fail() {
  printf '%s\n' "agent-desktop-manager: $*" >&2
  exit 1
}

[ "$#" -eq 0 ] || fail 'arguments are not accepted'
[ "${XDG_RUNTIME_DIR-}" ] || fail 'XDG_RUNTIME_DIR is required'
[ "${HOME-}" ] || fail 'HOME is required'
case "$XDG_RUNTIME_DIR" in /*) ;; *) fail 'runtime directory must be absolute' ;; esac
case "$HOME" in /*) ;; *) fail 'home must be absolute' ;; esac
[ -d "$XDG_RUNTIME_DIR" ] && [ ! -L "$XDG_RUNTIME_DIR" ] || fail 'invalid runtime directory'
[ "$('@coreutils@/stat' -c '%u:%a' "$XDG_RUNTIME_DIR")" = "$('@coreutils@/id' -u):700" ] || fail 'runtime directory ownership or mode'
[ "$('@coreutils@/stat' -f -c %t /sys/fs/cgroup)" = 63677270 ] || fail 'not a cgroup2 mount'
[ "$(</proc/self/cgroup)" = '0::/' ] || fail 'not at manager cgroup root'
mapfile -t members </sys/fs/cgroup/cgroup.procs
[ "${#members[@]}" -eq 1 ] && [ "${members[0]}" = "$$" ] || fail 'manager root is not exclusively occupied'
while IFS= read -r line; do
  case "$line" in
  'NoNewPrivs:'*) no_new_privs=${line#*:} ;;
  'Seccomp:'*) seccomp=${line#*:} ;;
  esac
done </proc/self/status
[ "${no_new_privs//[[:space:]]/}" = 1 ] || fail 'no-new-privileges is not set'
[ "${seccomp//[[:space:]]/}" = 2 ] || fail 'seccomp filter is not active'
for directory in / /etc /etc/systemd /run /run/systemd /usr /usr/local /usr/local/lib /usr/local/lib/systemd /usr/lib /usr/lib/systemd; do
  if [ -e "$directory" ] || [ -L "$directory" ]; then
    [ -d "$directory" ] && [ ! -L "$directory" ] && [ -x "$directory" ] || fail 'unsafe global configuration parent'
    [ ! -w "$directory" ] || fail 'writable global configuration parent'
    mode=$('@coreutils@/stat' -c %a "$directory") || fail 'cannot inspect global configuration parent'
    (((8#$mode & 8#022) == 0)) || fail 'unsafe global configuration parent'
  fi
done
for config in /etc/systemd/user.conf /etc/systemd/user.conf.d /run/systemd/user.conf.d /usr/local/lib/systemd/user.conf.d /usr/lib/systemd/user.conf.d; do
  [ ! -e "$config" ] && [ ! -L "$config" ] || fail 'global manager configuration is present'
done
[ ! -e "$XDG_RUNTIME_DIR/systemd" ] || fail 'runtime manager state already exists'
'@coreutils@/mkdir' -m 700 "$XDG_RUNTIME_DIR/systemd"
'@coreutils@/mkdir' -m 700 "$XDG_RUNTIME_DIR/systemd/transient"
exec '@coreutils@/env' -i \
  HOME="$HOME" \
  USER="$('@coreutils@/id' -un)" \
  LOGNAME="$('@coreutils@/id' -un)" \
  PATH='@coreutils@:@systemd@/bin:@dbus@/bin' \
  XDG_CONFIG_HOME='@out@/share/agent-desktop-runtime/manager-config' \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus" \
  SYSTEMD_UNIT_PATH="$XDG_RUNTIME_DIR/systemd/transient:@out@/share/agent-desktop-runtime/units" \
  SYSTEMD_GENERATOR_PATH='@out@/share/agent-desktop-runtime/empty' \
  SYSTEMD_ENVIRONMENT_GENERATOR_PATH='@out@/share/agent-desktop-runtime/empty' \
  SYSTEMD_LOG_TARGET=console \
  '@systemd@/lib/systemd/systemd' --user --log-target=console --default-standard-output=inherit --default-standard-error=inherit
