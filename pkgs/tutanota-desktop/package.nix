{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
}:
let
  pname = "tutanota-desktop";
  version = "371.261123.0";
  release = "https://github.com/tutao/tutanota/releases";
  tag = "tutanota-desktop-release-${version}";
  src = fetchurl {
    url = "${release}/download/${tag}/tutanota-desktop-linux.AppImage";
    hash = "sha256-amk1qmbgkv9QebEwxtDpW7ploFF+ldvr2YXsXyrViWI=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [ pkgs.libsecret ];
  nativeBuildInputs = [ makeWrapper ];
  extraInstallCommands = ''
    install -Dm444 ${contents}/tutanota-desktop.desktop -t "$out/share/applications"
    cp -r ${contents}/usr/share/icons/. "$out/share/icons"

    substituteInPlace "$out/share/applications/tutanota-desktop.desktop" \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'

    wrapProgram "$out/bin/${pname}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  meta = {
    description = "Tuta official desktop client";
    homepage = "https://tuta.com/";
    changelog = "${release}/tag/${tag}";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
