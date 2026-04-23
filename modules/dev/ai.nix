{ username, pkgs, ... }:
{
  home-manager.users.${username} = 
  { config, ...}:
  {
    home.packages = with pkgs; [
      gemini-cli
    ];
    
    systemd.user.services = {
      llama-server = {
        Unit = {
          Description = "LLaMA.cpp Inference Server";
          After = [ "network-online.target" ];
          PartOf = [ "llama-stack.service" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${(pkgs.llama-cpp.override { cudaSupport = true; })}/bin/llama-server --model ${config.home.homeDirectory}/Models/Qwen3.6-35B-A3B-UD-IQ4_NL_XL.gguf --port 8081 -ngl 99 -ctk q8_0 -ctv q8_0 -c 32768";
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
          Requires = [ "llama-server.service" "openwebui.service" ];
          After = [ "llama-server.service" "openwebui.service" ];
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
