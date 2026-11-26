{
  addDriverRunpath,
  autoPatchelfHook,
  cudaPackages_13_3,
  fetchurl,
  lib,
  openssl,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "unsloth-llama-cpp";
  version = "b12676-mix-c32dcc8";

  src = fetchurl {
    url = "https://github.com/unslothai/llama.cpp/releases/download/${finalAttrs.version}/app-${finalAttrs.version}-linux-x64-cuda13-portable.tar.gz";
    hash = "sha256-fpTLTZ4hUlu3sCHPy9LJA6L/n7e6RHYo5qqELvHJCzs=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    cudaPackages_13_3.cuda_cudart
    cudaPackages_13_3.libcublas
    openssl
    stdenv.cc.cc.lib
  ];
  autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];
  appendRunpaths = [ "${addDriverRunpath.driverLink}/lib" ];
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"/{bin,libexec/llama-cpp}
    cp -a lib*.so* llama llama-* "$out/libexec/llama-cpp/"
    for program in llama llama-*; do
      ln -s "../libexec/llama-cpp/$program" "$out/bin/$program"
    done
    install -Dm444 THIRD_PARTY_LICENSES.txt -t "$out/share/doc/unsloth-llama-cpp"
    runHook postInstall
  '';

  meta = {
    description = "Unsloth llama.cpp CUDA build with Inkling 2 support";
    homepage = "https://github.com/unslothai/llama.cpp";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "llama-server";
  };
})
