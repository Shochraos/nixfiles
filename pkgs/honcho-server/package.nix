{
  lib,
  python3Packages,
  fetchFromGitHub,
  fetchPypi,
  makeWrapper,
}:
python3Packages.buildPythonApplication rec {
  pname = "honcho-server";
  version = "3.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "plastic-labs";
    repo = "honcho";
    rev = "v${version}";
    hash = "sha256-g7RO8gMNZYSoEyw4Py+ORB/PYibwTIonHghmSO7Ms3c=";
  };

  nativeBuildInputs = [ makeWrapper ];

  build-system = with python3Packages; [
    hatch-vcs
  ];

  dependencies = with python3Packages; [
    cashews
    fastapi
    python-dotenv
    sqlalchemy
    fastapi-pagination
    pgvector
    sentry-sdk
    greenlet
    psycopg
    httpx
    rich
    nanoid
    alembic
    pyjwt
    tenacity
    tiktoken
    openai
    pydantic
    pydantic-settings
    typing-extensions
    json-repair
    redis
    prometheus-client
    uvicorn
    cloudevents
    langfuse
    google-genai
    pypdf
    anthropic
    uvloop
    python-multipart
    (python3Packages.buildPythonPackage rec {
      pname = "turbopuffer";
      version = "2.10.2";
      pyproject = true;
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-QySVFmEysH9XCqW10m2JxUxca3Cw6CjqYkArAjyaRlI=";
      };
      build-system = with python3Packages; [
        hatchling
        hatch-fancy-pypi-readme
      ];
      prePatch = "sed -i 's/hatchling==1.26.3/hatchling/' pyproject.toml";
      dependencies = with python3Packages; [
        httpx
        pydantic
        typing-extensions
        aiohttp
        distro
        orjson
        pybase64
        sniffio
      ];
      doCheck = false;
    })
  ];

  doCheck = false;

  pythonRelaxDeps = [
    "langfuse"
    "cashews"
  ];

  postFixup = ''
    mkdir -p $out/bin $out/share/honcho
    cp -r src migrations alembic.ini $out/share/honcho/
    ln -s ${python3Packages.python.interpreter} $out/bin/python
    depPath=$(echo $PYTHONPATH | tr ':' '\n' | while read dep; do echo -n "$dep:"; done)$out/lib/python3.14/site-packages
    makeWrapper ${python3Packages.uvicorn}/bin/uvicorn $out/bin/honcho-api \
      --prefix PYTHONPATH : "$out/share/honcho:$depPath" \
      --chdir "$out/share/honcho"
    cat > $out/bin/.honcho-migrate-unwrapped <<'EOF'
    import asyncio
    from src.db import init_db
    asyncio.run(init_db())
    EOF
    makeWrapper $out/bin/python $out/bin/honcho-migrate \
      --prefix PYTHONPATH : "$out/share/honcho:$depPath" \
      --add-flags "$out/bin/.honcho-migrate-unwrapped"
    makeWrapper $out/bin/python $out/bin/honcho-deriver \
      --prefix PYTHONPATH : "$out/share/honcho:$depPath" \
      --chdir "$out/share/honcho" \
      --add-flags "-m src.deriver"
  '';

  meta = with lib; {
    description = "Honcho local memory server (self-hosted, OpenAI-compatible LLM backends)";
    homepage = "https://github.com/plastic-labs/honcho";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
