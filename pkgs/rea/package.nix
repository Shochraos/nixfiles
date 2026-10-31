{
  lib,
  buildNpmPackage,
  fetchurl,
  ghidra,
  jdk21,
  nodejs_24,
  procps,
  python3,
}:
let
  version = "6.7.0";
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

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

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
      python3
      jdk21
    ])
  ];

  meta = {
    description = "Reverse engineer anything from your terminal or agent with one CLI and MCP server";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
