{
  fetchurl,
  lib,
  python314Packages,
}:
python314Packages.buildPythonPackage {
  pname = "honcho-ai";
  version = "2.7.0";
  pyproject = true;

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/59/6b/8d318c548fb3a7a2439162a1f03698c3fb031d6d5b565803ec7ee550bda1/honcho_ai-2.7.0.tar.gz";
    hash = "sha256-MHhuRC2Qfjyai7LDl1+b5LnygVw+04L02seaJdcTBSg=";
  };

  build-system = [ python314Packages.setuptools ];

  pythonRemoveDeps = [
    "httpx"
    "pydantic"
  ];

  doCheck = false;

  meta = {
    description = "Official Python SDK for the Honcho memory service; httpx and pydantic come from the sealed Hermes venv at runtime";
    homepage = "https://github.com/plastic-labs/honcho";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
