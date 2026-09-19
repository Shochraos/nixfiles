{ den, ... }:
{
  den.aspects.ai-local = {
    includes = [
      (den.batteries.unfree [
        "cuda_cccl"
        "cuda_compat"
        "cuda_cudart"
        "cuda_nvcc"
        "cuda_nvrtc"
        "libcublas"
      ])
    ];

    provides.to-users.homeManager =
      { lib, pkgs, ... }:
      let
        llama-cpp = pkgs.llama-cpp.override { cudaSupport = true; };

        qwenModel = pkgs.fetchurl {
          url = "https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-Q4_K_S.gguf";
          hash = "sha256-dbycituihC5y8KtSAaqgcTPFAQtWYwXAkYf8vc02QBc=";
        };

        reasoningTokens = 65536;
        responseTokens = 32768;

        llamaServerArgs = [
          "--model ${qwenModel}"
          "--alias qwen3.8-27b"
          "--port 8080"
          "--jinja"
          "-ctk q5_1"
          "-ctv q5_1"
          "-c 196608"
          "-n ${toString (reasoningTokens + responseTokens)}"
          "--reasoning-budget ${toString reasoningTokens}"
          "--spec-type draft-mtp"
          "-ctkd q5_1"
          "-ctvd q5_1"
          "--temp 1.0"
          "--top-p 0.95"
          "--top-k 20"
          "--min-p 0.0"
          "--presence-penalty 0.0"
          "--repeat-penalty 1.0"
        ];
      in
      {
        home.packages = [ llama-cpp ];

        systemd.user.services.llama-server = {
          Unit = {
            Description = "LLaMA.cpp Inference Server";
            After = [ "network-online.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${lib.getExe' llama-cpp "llama-server"} ${lib.concatStringsSep " " llamaServerArgs}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
  };
}
