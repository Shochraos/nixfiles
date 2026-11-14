{
  lib,
  stdenvNoCC,
  systemd,
  homeFiles,
  homePath,
  homeDirectory,
  userUnits,
  unitProviders,
  dbusProviders,
  uwsm,
  configDirectory ? ".config",
  dataDirectory ? ".local/share",
}:

let
  reservedUnits = [
    "basic.target"
    "dbus.service"
    "dbus.socket"
    "default.target"
    "exit.target"
    "shutdown.target"
    "systemd-exit.service"
  ];
  upstreamUnits = [
    "app.slice"
    "background.slice"
    "bluetooth.target"
    "graphical-session-pre.target"
    "graphical-session.target"
    "paths.target"
    "printer.target"
    "session.slice"
    "sockets.target"
    "sound.target"
    "timers.target"
    "xdg-desktop-autostart.target"
  ];
  unitPaths = [
    "${homeFiles}/${configDirectory}/systemd/user"
    "${homeFiles}/${dataDirectory}/systemd/user"
    "@profile@/units"
    "${uwsm}/lib/systemd/user"
    "${uwsm}/share/systemd/user"
    "@profile@/systemd-units"
  ]
  ++ lib.concatMap (provider: [
    "${provider}/share/systemd/user"
    "${provider}/lib/systemd/user"
  ]) unitProviders;
  serviceDirectories = map (provider: "${provider}/share/dbus-1/services") dbusProviders;
  lowerUnitDirectories =
    name:
    [
      "${uwsm}/lib/systemd/user"
      "${uwsm}/share/systemd/user"
    ]
    ++ lib.optionals (builtins.elem name upstreamUnits) [ "${systemd}/example/systemd/user" ]
    ++ lib.concatMap (provider: [
      "${provider}/share/systemd/user"
      "${provider}/lib/systemd/user"
    ]) unitProviders;
  dependencyLinks =
    name: unit:
    lib.concatStrings (
      lib.mapAttrsToList
        (
          field: suffix:
          lib.concatMapStrings (target: ''
            mkdir -p "$out/units/"${lib.escapeShellArg "${target}.${suffix}"}
            ln -s ${lib.escapeShellArg "../${name}"} "$out/units/"${lib.escapeShellArg "${target}.${suffix}/${name}"}
          '') (unit.${field} or [ ])
        )
        {
          wantedBy = "wants";
          requiredBy = "requires";
          upheldBy = "upholds";
        }
    );
  nativeUnit =
    name: unit:
    let
      source = "${unit.unit}/${name}";
      strategy = unit.overrideStrategy or "asDropinIfExists";
    in
    ''
      source=${lib.escapeShellArg source}
      base=
      for directory in ${lib.escapeShellArgs (lowerUnitDirectories name)}; do
        if [ -e "$directory/"${lib.escapeShellArg name} ] || [ -L "$directory/"${lib.escapeShellArg name} ]; then
          base="$directory/"${lib.escapeShellArg name}
          break
        fi
      done
      if [ ${lib.escapeShellArg strategy} = asDropin ] || { [ ${lib.escapeShellArg strategy} = asDropinIfExists ] && [ -n "$base" ] && [ "$(readlink -f "$source")" != /dev/null ]; }; then
        if [ -n "$base" ]; then
          ln -s "$base" "$out/units/"${lib.escapeShellArg name}
        fi
        mkdir -p "$out/units/"${lib.escapeShellArg "${name}.d"}
        ln -s "$source" "$out/units/"${lib.escapeShellArg "${name}.d/overrides.conf"}
      else
        ln -s "$source" "$out/units/"${lib.escapeShellArg name}
      fi
      ${lib.concatMapStrings (alias: ''
        ln -s ${lib.escapeShellArg name} "$out/units/"${lib.escapeShellArg alias}
      '') (unit.aliases or [ ])}
      ${dependencyLinks name unit}
    '';
in
assert lib.assertMsg (
  builtins.match "/[A-Za-z0-9_./-]+" homeDirectory != null && !(lib.hasInfix ".." homeDirectory)
) "homeDirectory must be a simple absolute path";
assert lib.assertMsg (lib.all
  (
    value:
    builtins.match "[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*" value != null && !(lib.hasInfix ".." value)
  )
  [
    configDirectory
    dataDirectory
  ]
) "XDG directories must be simple relative paths";
assert lib.assertMsg (lib.all (
  name: builtins.match "[A-Za-z0-9_.@:-]+" name != null && !(builtins.elem name reservedUnits)
) (builtins.attrNames userUnits)) "invalid or reserved unit name";
assert lib.assertMsg (lib.all (
  unit:
  lib.all (value: builtins.match "[A-Za-z0-9_.@:-]+" value != null) (
    (unit.wantedBy or [ ]) ++ (unit.requiredBy or [ ]) ++ (unit.upheldBy or [ ])
  )
  && lib.all (
    value: builtins.match "[A-Za-z0-9_.@:-]+" value != null && !(builtins.elem value reservedUnits)
  ) (unit.aliases or [ ])
) (builtins.attrValues userUnits)) "invalid or reserved unit link";
stdenvNoCC.mkDerivation {
  pname = "agent-desktop-profile";
  version = "1";
  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/units" "$out/systemd-units" "$out/sources"
    for directory in ${
      lib.escapeShellArgs (
        [
          "${homeFiles}/${configDirectory}/systemd/user"
          "${homeFiles}/${dataDirectory}/systemd/user"
          "${uwsm}/lib/systemd/user"
          "${uwsm}/share/systemd/user"
        ]
        ++ lib.concatMap (provider: [
          "${provider}/share/systemd/user"
          "${provider}/lib/systemd/user"
        ]) unitProviders
      )
    }; do
      for name in ${
        lib.escapeShellArgs (
          map (name: "${name}.d") reservedUnits
          ++ [
            "service.d"
            "socket.d"
            "target.d"
            "systemd-.service.d"
          ]
        )
      }; do
        if [ -e "$directory/$name" ] || [ -L "$directory/$name" ]; then
          printf 'reserved unit drop-in: %s\n' "$directory/$name" >&2
          exit 1
        fi
      done
    done
    for unit in ${lib.escapeShellArgs upstreamUnits}; do
      test -e "${systemd}/example/systemd/user/$unit"
      ln -s "${systemd}/example/systemd/user/$unit" "$out/systemd-units/$unit"
    done
    ln -s ${homeFiles} "$out/sources/home-files"
    ln -s ${homePath} "$out/sources/home-path"
    ln -s ${uwsm} "$out/sources/uwsm"
    ${lib.concatStringsSep "\n" (
      lib.imap0 (index: provider: ''
        ln -s ${provider} "$out/sources/unit-provider-${toString index}"
      '') unitProviders
    )}
    ${lib.concatStringsSep "\n" (
      lib.imap0 (index: provider: ''
        ln -s ${provider} "$out/sources/dbus-provider-${toString index}"
      '') dbusProviders
    )}
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList nativeUnit userUnits)}
    runHook postInstall
  '';
  passthru = {
    inherit
      homeFiles
      homePath
      homeDirectory
      configDirectory
      dataDirectory
      unitPaths
      serviceDirectories
      ;
  };
}
