{
  lib,
  buildNpmPackage,
  callPackage,
  fetchurl,
  ghidra,
  jdk21,
  nodejs_24,
  patchelf,
  procps,
  python3,
  stdenv,
  pythonEnvironment ? callPackage ./python.nix { inherit python3; },
}:
let
  version = "6.7.0";
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
buildNpmPackage {
  pname = "rea-agents";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${version}.tgz";
    hash = "sha256-IJWKZtuhoBHlCkhr65Rjo0MSjtNoyYT5QGU2LBP1H5A=";
  };

  npmDepsHash = "sha256-HnB8R75VT1Ceq+oGqgdV7dAgIhJ1IHVeZJWlR5Fpj90=";

  nodejs = nodejs_24;

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];
  npmInstallFlags = [ "--omit=dev" ];

  nativeBuildInputs = lib.optional (fridaBinding != null && stdenv.hostPlatform.isLinux) patchelf;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  postInstall = lib.optionalString (fridaBinding != null) (
    ''
      tar -xzf ${fridaBinding} -C "$out/lib/node_modules/rea-agents/node_modules/frida" build/frida_binding.node
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      patchelf --set-rpath ${
        lib.makeLibraryPath [ stdenv.cc.libc ]
      } "$out/lib/node_modules/rea-agents/node_modules/frida/build/frida_binding.node"
    ''
  );

  makeWrapperArgs = [
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

  passthru = { inherit pythonEnvironment; };

  meta = {
    description = "Reverse engineer anything from your terminal or agent with one CLI and MCP server";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
