{
  lib,
  stdenvNoCC,
  fetchurl,
  coreutils,
  makeWrapper,
  p7zip,
  wine,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mp3tag";
  version = "3.32";

  src = fetchurl {
    url = "https://download.mp3tag.de/versions/mp3tagv${
      builtins.replaceStrings [ "." ] [ "" ] finalAttrs.version
    }setup.exe";
    hash = "sha256-oejLk5P8KDe2ngnKN/pnu1ar3WCgGnxtpxz0LDTD/SY=";
  };

  nativeBuildInputs = [
    makeWrapper
    p7zip
  ];

  unpackPhase = ''
    runHook preUnpack
    7z x -y -bso0 -bsp0 -o. "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/share/${finalAttrs.pname}"
    cp -r data help lang Mp3tag.exe "$out/share/${finalAttrs.pname}"

    makeWrapper ${lib.getExe wine} "$out/bin/mp3tag" \
      --add-flags "$out/share/${finalAttrs.pname}/Mp3tag.exe" \
      --run 'export WINEPREFIX="''${WINEPREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/mp3tag/wine}"' \
      --run '${lib.getExe' coreutils "mkdir"} -p "$WINEPREFIX"'

    runHook postInstall
  '';

  meta = {
    description = "Editor for metadata of audio files, run under Wine";
    homepage = "https://www.mp3tag.de";
    license = lib.licenses.unfree;
    mainProgram = "mp3tag";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
