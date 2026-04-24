{ username, pkgs, ... }:
{
  home-manager.users.${username} =
    { config, ... }:
    {
      home.packages = with pkgs; [
        gemini-cli
        opencode
        (pkgs.llama-cpp.override { cudaSupport = true; })
      ];

      xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        model = "my-local/qwen3.6";
        provider = {
          "my-local" = {
            npm = "@ai-sdk/openai-compatible";
            name = "Local RTX 4090";
            options = {
              baseURL = "http://127.0.0.1:8081/v1";
              apiKey = "sk-local";
            };
            models = {
              "qwen3.6" = {
                name = "Qwen 3.6 35B Local";
                limit = {
                  context = 262144;
                  output = 32768;
                };
              };
            };
          };
        };
      };

      systemd.user.services = {
        llama-server = {
          Unit = {
            Description = "LLaMA.cpp Inference Server";
            After = [ "network-online.target" ];
            PartOf = [ "llama-stack.service" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${
              (pkgs.llama-cpp.override { cudaSupport = true; })
              }/bin/llama-server --model ${config.home.homeDirectory}/Models/Qwen3.6-35B-A3B-UD-Q5_K_XL.gguf --port 8081 --jinja -ctk q8_0 -ctv q8_0 -c 262144 -n 32768 --temp 0.6 --top-p 0.95 --top-k 20 --presence-penalty 0.0 --min-p 0.0";            
              Restart = "on-failure";
            RestartSec = 5;
          };
        };

        openwebui = {
          Unit = {
            Description = "Open WebUI";
            After = [ "network-online.target" ];
            PartOf = [ "llama-stack.service" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.coreutils}/bin/env DATA_DIR=${config.home.homeDirectory}/Applications/open-webui ${pkgs.open-webui}/bin/open-webui serve";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        llama-stack = {
          Unit = {
            Description = "LLaMA Stack";
            Requires = [
              "llama-server.service"
              "openwebui.service"
            ];
            After = [
              "llama-server.service"
              "openwebui.service"
            ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = "yes";
            ExecStart = "${pkgs.coreutils}/bin/true";
          };
        };
      };

    };
}
