{
  stdenvNoCC,
  bash,
  coreutils,
  systemd,
  dbus,
  desktopUnits ? null,
}:

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
      --replace-fail '@out@' "$out"
    substituteInPlace "$out/share/agent-desktop-runtime/units/dbus.service" \
      --replace-fail '@dbus@' '${dbus}' \
      --replace-fail '@out@' "$out"
    ${
      if desktopUnits == null then
        ""
      else
        ''
          for unit in ${desktopUnits}/*; do
            [ -e "$unit" ] || [ -L "$unit" ] || continue
            name="''${unit##*/}"
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
