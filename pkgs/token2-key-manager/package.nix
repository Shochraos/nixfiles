{
  autoPatchelfHook,
  cairo,
  dbus,
  dpkg,
  fetchurl,
  gdk-pixbuf,
  glib,
  gtk3,
  lib,
  libsoup_3,
  makeWrapper,
  openssl,
  pcsclite,
  stdenv,
  udev,
  wayland,
  webkitgtk_4_1,
  wrapGAppsHook3,
  zlib,
}:
let
  releases = "https://github.com/token2/fido2-manage/releases";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "token2-key-manager";
  version = "0.2.3";

  src = fetchurl {
    url = "${releases}/download/${finalAttrs.version}/Token2-key-manager_${finalAttrs.version}_amd64.deb";
    hash = "sha256-r24OoLhCnWw4nvyRQx52jEJyMFCNs2nqvtyYiUk7PV8=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    (wrapGAppsHook3.override { inherit makeWrapper; })
  ];
  buildInputs = [
    cairo
    dbus
    gdk-pixbuf
    glib
    gtk3
    libsoup_3
    openssl
    pcsclite
    stdenv.cc.cc.lib
    udev
    wayland
    webkitgtk_4_1
    zlib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --extract "$src" .
    runHook postUnpack
  '';

  dontBuild = true;
  installPhase = ''
    runHook preInstall
    payload=opt/${finalAttrs.pname}
    install -Dm755 "$payload/"{token2-key-manager,fido2-manage,token2-piv-tool} -t "$out/bin"
    install -Dm755 "$payload/"{libcbor.so.0.10,libt2piv.so.2} -t "$out/lib"
    cp -r usr/share "$out/share"
    runHook postInstall
  '';

  dontWrapGApps = true;
  preFixup = ''
    wrapGApp "$out/bin/${finalAttrs.pname}" --run \
      'if [ -e /proc/driver/nvidia ]; then export WEBKIT_DISABLE_DMABUF_RENDERER=1; fi'
  '';

  meta = {
    description = "Token2 security key manager for FIDO2, PIV, and OTP";
    homepage = "https://github.com/token2/fido2-manage";
    changelog = "${releases}/tag/${finalAttrs.version}";
    license = lib.licenses.bsd2;
    mainProgram = finalAttrs.pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
