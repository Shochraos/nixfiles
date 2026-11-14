#!/usr/bin/env bash
set -eu
exec '@coreutils@/env' \
  HOME='@home@' \
  XDG_CONFIG_HOME='@config-home@' \
  XDG_CONFIG_DIRS='@empty@' \
  XDG_DATA_HOME='@data-home@' \
  XDG_DATA_DIRS='@data-dirs@' \
  '@systemd@/lib/systemd/user-generators/systemd-xdg-autostart-generator' "$@"
