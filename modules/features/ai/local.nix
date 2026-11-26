{ config, den, ... }:
{
  den.aspects.ai-local = {
    includes = [
      (den.batteries.unfree [
        "cccl"
        "cuda_compat"
        "cuda_crt"
        "cuda_cudart"
        "cuda_nvcc"
        "cuda_nvrtc"
        "libcublas"
        "libnvvm"
      ])
    ];

    provides.to-users.homeManager =
      { lib, pkgs, ... }:
      let
        llama-cpp = pkgs.callPackage config.packageSources.unslothLlamaCpp { };
        inklingModel = pkgs.fetchurl {
          url = "https://huggingface.co/unsloth/Inkling-2-Mini-GGUF/resolve/8078d149286eec7193795413b9e0643da6d11fa1/Inkling-2-Mini-UD-Q4_K_XL.gguf";
          hash = "sha256-5kJ2ZW8HLpshl6YXI2Z8vbcdpmpxb/2WblcsIQiPPNM=";
        };

        llamaServerArgs = [
          "--model ${inklingModel}"
          "--alias inkling-2-mini"
          "--host 127.0.0.1"
          "--port 8080"
          "--jinja"
          "--ctx-size 262144"
          "--parallel 1"
          "--cache-type-k q8_0"
          "--cache-type-v q8_0"
          "--device CUDA0"
          "--n-gpu-layers 99"
          "--fit off"
          "--flash-attn on"
          "--ubatch-size 512"
          "--reasoning-effort low"
          "--temp 1.0"
          "--top-p 1.0"
          "--top-k 0"
          "--min-p 0.0"
        ];
      in
      {
        home.packages = [ llama-cpp ];

        systemd.user.services.llama-server = {
          Unit = {
            Description = "Inkling 2 Mini inference server";
            After = [ "network-online.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${lib.getExe llama-cpp} ${lib.concatStringsSep " " llamaServerArgs}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
  };
}
