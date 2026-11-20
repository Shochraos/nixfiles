{
  lib,
  fetchurl,
  ghidra,
  jdk21,
  makeWrapper,
  nodejs_24,
  patchelf,
  procps,
  rea,
  python3,
  stdenv,
  versionCheckHook,
  pythonEnvironment ? python3.withPackages (ps: [
    ps.pwntools
    ps.pyelftools
    ps.unicorn
  ]),
}:
let
  fridaVersion = "17.23.2";
  fridaPrebuild =
    {
      x86_64-linux = {
        platform = "linux-x64";
        hash = "sha256-n6j2aM6R6wNxPoVk3k+PveIyIz7pHXKcFnc/3hHbrpU=";
      };
      aarch64-linux = {
        platform = "linux-arm64";
        hash = "sha256-EQg/AWpCnodQbNaBZr0URdqP69UGok7fP2xKmno+qf4=";
      };
      i686-linux = {
        platform = "linux-ia32";
        hash = "sha256-r+TSw4Z0RO8LwhpwvpEjrl5jxwQS0CPooz1AqUPhFEY=";
      };
      armv7l-linux = {
        platform = "linux-armv7l";
        hash = "sha256-UFaV6OcrxMyYECRMGXJVAIlnmEl7Rlu5Nx5YsjF+0RE=";
      };
      aarch64-darwin = {
        platform = "darwin-arm64";
        hash = "sha256-hQ+6Igotm2quKCrG3eN/SIR+c1l7egbWSHN/+a3cM0A=";
      };
      x86_64-darwin = {
        platform = "darwin-x64";
        hash = "sha256-+JU7CXIMvczSccHWyqT/8IVHSp8k3vP+RhYFJqrNtAs=";
      };
    }
    .${stdenv.hostPlatform.system} or null;
  fridaBinding =
    if
      fridaPrebuild != null
      && (stdenv.hostPlatform.isDarwin || stdenv.hostPlatform.isGnu)
      && (
        stdenv.hostPlatform.system != "armv7l-linux" || stdenv.hostPlatform.parsed.abi.name == "gnueabihf"
      )
    then
      fetchurl {
        url = "https://github.com/frida/frida/releases/download/${fridaVersion}/frida-v${fridaVersion}-napi-v8-${fridaPrebuild.platform}.tar.gz";
        inherit (fridaPrebuild) hash;
      }
    else
      null;
  runtimePath = lib.makeBinPath [
    nodejs_24
    procps
    pythonEnvironment
    jdk21
  ];
in
stdenv.mkDerivation {
  inherit (rea) pname version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optional (fridaBinding != null && stdenv.hostPlatform.isLinux) patchelf;

  installPhase = ''
    runHook preInstall

    srcPkg="${rea}/lib/node_modules/rea-agents"
    dstPkg="$out/lib/node_modules/rea-agents"
    mkdir -p "$dstPkg/node_modules" "$out/bin"

    shopt -s dotglob nullglob
    for entry in "$srcPkg"/*; do
      name="$(basename "$entry")"
      case "$name" in
        dist|scripts|package.json)
          cp -r --no-preserve=mode "$entry" "$dstPkg/$name"
          ;;
        node_modules)
          ;;
        *)
          ln -s "$entry" "$dstPkg/$name"
          ;;
      esac
    done

    for entry in "$srcPkg/node_modules"/*; do
      name="$(basename "$entry")"
      if [ "$name" = "frida" ]; then
        cp -r --no-preserve=mode "$entry" "$dstPkg/node_modules/frida"
      else
        ln -s "$entry" "$dstPkg/node_modules/$name"
      fi
    done

    ${lib.optionalString (fridaBinding != null) (
      ''
        tar -xzf ${fridaBinding} -C "$dstPkg/node_modules/frida" build/frida_binding.node
      ''
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        patchelf --set-rpath ${
          lib.makeLibraryPath [ stdenv.cc.libc ]
        } "$dstPkg/node_modules/frida/build/frida_binding.node"
      ''
    )}

    for binName in rea rea-agents; do
      makeWrapper ${lib.getExe nodejs_24} "$out/bin/$binName" \
        --add-flags "$dstPkg/scripts/rea.mjs" \
        --set-default GHIDRA_INSTALL_DIR "${ghidra}/lib/ghidra" \
        --prefix PATH : "${runtimePath}"
    done

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/rea";
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru = (rea.passthru or { }) // {
    inherit pythonEnvironment;
  };

  meta = rea.meta // {
    platforms = lib.intersectLists rea.meta.platforms ghidra.meta.platforms;
  };
}
