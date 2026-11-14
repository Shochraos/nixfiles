{
  lib,
  stdenv,
  bash,
  systemd,
  coreutils,
  outerUnit,
  runtimeDirectory,
  homeDirectory,
}:
assert builtins.match "[A-Za-z0-9_.@-]+\\.service" outerUnit != null;
assert !(lib.hasPrefix "-" outerUnit);
assert builtins.match "/[A-Za-z0-9_./-]+" runtimeDirectory != null;
assert builtins.match "/[A-Za-z0-9_./-]+" homeDirectory != null;
assert !(lib.hasInfix "/../" "${runtimeDirectory}/" || lib.hasSuffix "/.." runtimeDirectory);
assert !(lib.hasInfix "/../" "${homeDirectory}/" || lib.hasSuffix "/.." homeDirectory);
stdenv.mkDerivation {
  pname = "agent-desktop-entry";
  version = "1";
  dontUnpack = true;
  inherit outerUnit runtimeDirectory homeDirectory;
  bashPath = "${bash}/bin/bash";
  systemctlPath = "${systemd}/bin/systemctl";
  systemdRunPath = "${systemd}/bin/systemd-run";
  statPath = "${coreutils}/bin/stat";
  dispatcherPath = "${placeholder "out"}/libexec/agent-desktop-dispatch";
  buildPhase = ''
    substituteAll ${./entry.c} entry.c
    substituteAll ${./dispatch.sh} dispatch.sh
    substituteInPlace dispatch.sh \
      --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash'
    $CC -std=c11 -Wall -Wextra -Werror -O2 entry.c -o agent-desktop-entry
  '';
  installPhase = ''
    install -Dm755 agent-desktop-entry "$out/bin/agent-desktop-entry"
    install -Dm755 dispatch.sh "$out/libexec/agent-desktop-dispatch"
  '';
  meta.platforms = lib.platforms.linux;
}
