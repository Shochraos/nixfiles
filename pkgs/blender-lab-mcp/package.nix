{
  lib,
  fetchzip,
  fetchurl,
  python3Packages,
}:
let
  source = fetchzip {
    url = "https://projects.blender.org/api/v1/repos/lab/blender_mcp/archive/2cea8d566dde07fbac28a61d698909d69724e853.tar.gz";
    hash = "sha256-pYeByO4Oi5eyynsJhGVd1vBWXHvhGn+Y5LGit6Kazlw=";
  };
  sdk = python3Packages.buildPythonPackage {
    pname = "mcp";
    version = "1.26.0";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/fc/6d/62e76bbb8144d6ed86e202b5edd8a4cb631e7c8130f3f4893c3f90262b10/mcp-1.26.0.tar.gz";
      hash = "sha256-224u9JHuzBoNk3EadvKN7C4FmZ+Tr9SHldocETcULGY=";
    };
    build-system = with python3Packages; [
      hatchling
      uv-dynamic-versioning
    ];
    dependencies = with python3Packages; [
      anyio
      httpx
      httpx-sse
      pydantic
      starlette
      python-multipart
      sse-starlette
      pydantic-settings
      uvicorn
      jsonschema
      pyjwt
      cryptography
      typing-extensions
      typing-inspection
      typer
      python-dotenv
    ];
    pythonImportsCheck = [ "mcp" ];
  };
in
python3Packages.buildPythonPackage {
  pname = "blender-mcp";
  version = "1.0.3";
  pyproject = true;
  src = source;
  sourceRoot = "source/mcp";
  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [
    docutils
    sdk
    pyyaml
  ];
  pythonImportsCheck = [ "blmcp" ];
  passthru.addonSource = "${source}/addon";
  meta = {
    description = "Official Blender Lab MCP server";
    homepage = "https://projects.blender.org/lab/blender_mcp";
    license = lib.licenses.gpl3Plus;
    mainProgram = "blender-mcp";
  };
}
