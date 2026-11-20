{
  cmake,
  fetchurl,
  pkg-config,
  python3,
}:
let
  pyelftools = python3.pkgs.pyelftools.overridePythonAttrs (_: rec {
    version = "0.33";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/a3/11/767522582afab1b884d277de0e6e011640cb9d7292a38694b4b1a1df1ae8/pyelftools-0.33.tar.gz";
      hash = "sha256-Zg2C3L646D0XAr2X8iP3YWJdoGERwMyYjqxrirDBth8=";
    };
  });

  unicorn = python3.pkgs.buildPythonPackage rec {
    pname = "unicorn";
    version = "2.1.2";
    format = "setuptools";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/90/12/a10f01a3e1dafcd21e2eb0c0d99bb51d5bda1d3fee20047cb2a4b2de6285/unicorn-2.1.2.tar.gz";
      hash = "sha256-5KnWcb3qcYBvKaOWc0z7gzF/gpQ7UtAAHTvKHcuu6JM=";
    };

    sourceRoot = "unicorn-${version}";

    build-system = with python3.pkgs; [
      setuptools
      versioningit
    ];

    nativeBuildInputs = [
      cmake
      pkg-config
    ];

    dontUseCmakeConfigure = true;
  };
in
(python3.override {
  packageOverrides = _self: _super: {
    inherit pyelftools unicorn;
  };
}).withPackages
  (ps: [
    ps.pwntools
    ps.pyelftools
    ps.unicorn
  ])
