{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  fontconfig,
  freetype,
  harfbuzz,
  icu,
  libGL,
  libice,
  libjpeg_turbo,
  libpng,
  libsm,
  libx11,
  libxcb,
  openssl,
  skia,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "irony-mod-manager";
  version = "1.27.199";

  src = fetchzip {
    url = "https://github.com/bcssov/IronyModManager/releases/download/v${finalAttrs.version}/linux-x64.zip";
    hash = "sha256-T97EFWlMm+5X9Rzmx/T4P3hjBrMHhJgkWS1JrocRlHM=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  postPatch = ''
    rm libcoreclrtraceptprovider.so
  '';

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    fontconfig
    freetype
    harfbuzz
    icu
    libGL
    libice
    libjpeg_turbo
    libpng
    libsm
    libx11
    libxcb
    openssl
    skia
    zlib
  ];

  installPhase = ''
    runHook preInstall

    install -d "$out/share/${finalAttrs.pname}"
    cp -r . "$out/share/${finalAttrs.pname}"
    chmod +x "$out/share/${finalAttrs.pname}/IronyModManager"

    makeWrapper "$out/share/${finalAttrs.pname}/IronyModManager" "$out/bin/IronyModManager" \
      --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 0 \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --chdir "$out/share/${finalAttrs.pname}"

    runHook postInstall
  '';

  meta = {
    description = "Mod manager for Paradox games";
    homepage = "https://bcssov.github.io/IronyModManager";
    license = lib.licenses.mit;
    mainProgram = "IronyModManager";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
