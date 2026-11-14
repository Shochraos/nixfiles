{
  lib,
  stdenvNoCC,
  bash,
  coreutils,
  systemd,
  dbus,
  desktopUnits ? null,
  desktopProfile ? null,
}:

let
  enabled = desktopProfile != null;
  empty = "@out@/share/agent-desktop-runtime/empty";
  profileUnits =
    if enabled then
      map (lib.replaceStrings [ "@profile@" ] [ (toString desktopProfile) ]) desktopProfile.unitPaths
    else
      [ ];
  unitPath =
    if enabled then
      ":$XDG_RUNTIME_DIR/systemd/generator.early:$XDG_RUNTIME_DIR/systemd/generator:$XDG_RUNTIME_DIR/systemd/generator.late:${lib.concatStringsSep ":" profileUnits}"
    else
      "";
  generatorPath = if enabled then "@out@/share/agent-desktop-runtime/generators" else empty;
  configHome =
    if enabled then "${desktopProfile.homeDirectory}/${desktopProfile.configDirectory}" else "";
  dataHome =
    if enabled then "${desktopProfile.homeDirectory}/${desktopProfile.dataDirectory}" else "";
  dataDirs = if enabled then "${desktopProfile.homePath}/share" else "";
  appPath =
    if enabled then
      "${desktopProfile.homePath}/bin:${coreutils}/bin:${systemd}/bin:${dbus}/bin"
    else
      "";
  defaultEnvironment =
    if enabled then
      lib.concatStringsSep " " (
        lib.mapAttrsToList (name: value: "${name}=${lib.escapeShellArg value}") {
          HOME = desktopProfile.homeDirectory;
          XDG_CONFIG_HOME = configHome;
          XDG_CONFIG_DIRS = empty;
          XDG_DATA_HOME = dataHome;
          XDG_DATA_DIRS = dataDirs;
          PATH = appPath;
        }
      )
    else
      "";
in
stdenvNoCC.mkDerivation {
  pname = "agent-desktop-runtime";
  version = "1";
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/agent-desktop-runtime/units" "$out/share/agent-desktop-runtime/empty"
    install -m755 ${./bootstrap.sh} "$out/bin/agent-desktop-manager"
    install -Dm444 ${./manager.conf} "$out/share/agent-desktop-runtime/manager-config/systemd/user.conf"
    cp ${./units}/* "$out/share/agent-desktop-runtime/units/"
    cp ${./bus.conf} "$out/share/agent-desktop-runtime/bus.conf"
    substituteInPlace "$out/bin/agent-desktop-manager" \
      --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash' \
      --replace-fail '@coreutils@' '${coreutils}/bin' \
      --replace-fail '@systemd@' '${systemd}' \
      --replace-fail '@dbus@' '${dbus}' \
      --replace-fail '@profile-unit-path@' ${lib.escapeShellArg unitPath} \
      --replace-fail '@generator-path@' ${lib.escapeShellArg generatorPath} \
      --replace-fail '@out@' "$out"
    substituteInPlace "$out/share/agent-desktop-runtime/units/dbus.service" \
      --replace-fail '@dbus@' '${dbus}' \
      --replace-fail '@out@' "$out"
    ${lib.optionalString enabled ''
      chmod u+w "$out/share/agent-desktop-runtime/manager-config/systemd/user.conf"
      printf '%s\n' ${lib.escapeShellArg "DefaultEnvironment=${defaultEnvironment}"} >> "$out/share/agent-desktop-runtime/manager-config/systemd/user.conf"
      substituteInPlace "$out/share/agent-desktop-runtime/manager-config/systemd/user.conf" --replace-fail '@out@' "$out"
      mkdir -p "$out/share/agent-desktop-runtime/generators"
      install -m755 ${./autostart-generator.sh} "$out/share/agent-desktop-runtime/generators/xdg-autostart-generator"
      substituteInPlace "$out/share/agent-desktop-runtime/generators/xdg-autostart-generator" \
        --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash' \
        --replace-fail '@coreutils@' '${coreutils}/bin' \
        --replace-fail '@home@' ${lib.escapeShellArg desktopProfile.homeDirectory} \
        --replace-fail '@config-home@' ${lib.escapeShellArg configHome} \
        --replace-fail '@data-home@' ${lib.escapeShellArg dataHome} \
        --replace-fail '@data-dirs@' ${lib.escapeShellArg dataDirs} \
        --replace-fail '@empty@' "$out/share/agent-desktop-runtime/empty" \
        --replace-fail '@systemd@' '${systemd}'
      substituteInPlace "$out/share/agent-desktop-runtime/bus.conf" --replace-fail '</busconfig>' ${
        lib.escapeShellArg (
          (lib.concatMapStrings (
            dir: "<servicedir>${lib.escapeXML dir}</servicedir>\n"
          ) desktopProfile.serviceDirectories)
          + "</busconfig>"
        )
      }
    ''}
    ${
      if desktopUnits == null then
        ""
      else
        ''
          for unit in ${desktopUnits}/*; do
            [ -e "$unit" ] || [ -L "$unit" ] || continue
            name="''${unit##*/}"
            ${lib.optionalString enabled ''
              case "$name" in
                basic.target.d|dbus.service.d|dbus.socket.d|default.target.d|exit.target.d|shutdown.target.d|systemd-exit.service.d|service.d|socket.d|target.d|systemd-.service.d)
                  printf 'reserved unit drop-in: %s\n' "$name" >&2
                  exit 1
                  ;;
              esac
            ''}
            if [ -e "$out/share/agent-desktop-runtime/units/$name" ] || [ -L "$out/share/agent-desktop-runtime/units/$name" ]; then
              printf 'reserved unit: %s\n' "$name" >&2
              exit 1
            fi
            ln -s "$unit" "$out/share/agent-desktop-runtime/units/$name"
          done
        ''
    }
    runHook postInstall
  '';
}
