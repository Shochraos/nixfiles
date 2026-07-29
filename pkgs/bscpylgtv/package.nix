{
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "bscpylgtv";
  version = "0.5.1";
  pyproject = true;

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-act/rqkCS/qsGYREeeNsE1FZItaMbniIXlZ4UU/iZA8=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    sqlitedict
    websockets
  ];

  doCheck = false;

  pythonImportsCheck = [ "bscpylgtv" ];

  meta = {
    description = "Library and CLI to control LG webOS smart TVs over the local network";
    homepage = "https://github.com/chros73/bscpylgtv";
    license = lib.licenses.mit;
    mainProgram = "bscpylgtvcommand";
    platforms = lib.platforms.all;
  };
}
