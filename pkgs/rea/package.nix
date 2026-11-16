{
  lib,
  callPackage,
  fetchurl,
  ghidra,
  jdk21,
  nodejs_24,
  patchelf,
  procps,
  rea,
  python3,
  stdenv,
  pythonEnvironment ? callPackage ./python.nix { inherit python3; },
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
in
rea.overrideAttrs (previous: {
  nodejs = nodejs_24;

  nativeBuildInputs =
    (previous.nativeBuildInputs or [ ])
    ++ lib.optional (fridaBinding != null && stdenv.hostPlatform.isLinux) patchelf;

  postInstall =
    (previous.postInstall or "")
    + "\n"
    + lib.optionalString (fridaBinding != null) (
      ''
        tar -xzf ${fridaBinding} -C "$out/lib/node_modules/rea-agents/node_modules/frida" build/frida_binding.node
      ''
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        patchelf --set-rpath ${
          lib.makeLibraryPath [ stdenv.cc.libc ]
        } "$out/lib/node_modules/rea-agents/node_modules/frida/build/frida_binding.node"
      ''
    );

  makeWrapperArgs = (previous.makeWrapperArgs or [ ]) ++ [
    "--set-default"
    "GHIDRA_INSTALL_DIR"
    "${ghidra}/lib/ghidra"
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [
      nodejs_24
      procps
      pythonEnvironment
      jdk21
    ])
  ];

  passthru = (previous.passthru or { }) // {
    inherit pythonEnvironment;
  };

  meta = previous.meta // {
    platforms = lib.intersectLists previous.meta.platforms ghidra.meta.platforms;
  };
})
