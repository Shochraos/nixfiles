{ inputs, lib, ... }:
{
  den.aspects.ai = {
    __functor =
      self: args:
      let
        unknown = if builtins.isAttrs args then builtins.attrNames (removeAttrs args [ "local" ]) else [ ];
      in
      if !builtins.isAttrs args then
        throw "den.aspects.ai must be called with an argument set, e.g. (ai { local = true; })"
      else if unknown != [ ] then
        throw "den.aspects.ai: unknown argument(s) ${lib.concatStringsSep ", " unknown} — expected only 'local'"
      else
        {
          includes = [ self.tools ] ++ lib.optional (args.local or false) self.local;
        };

    provides.tools.provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.claude-code
          inputs.omp-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };

    provides.local.provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        llama-cpp = pkgs.llama-cpp.override { cudaSupport = true; };
      in
      {
        home.packages = [ llama-cpp ];

        systemd.user.services = {
          llama-server = {
            Unit = {
              Description = "LLaMA.cpp Inference Server";
              After = [ "network-online.target" ];
              PartOf = [ "llama-stack.target" ];
            };
            Service = {
              Type = "simple";
              ExecStart = "${llama-cpp}/bin/llama-server --model ${config.home.homeDirectory}/Models/Qwen3.6-35B-A3B-UD-Q5_K_XL.gguf --port 8081 --jinja -ctk q8_0 -ctv q8_0 -c 262144 -n 32768 --temp 0.6 --top-p 0.95 --top-k 20 --presence-penalty 0.0 --min-p 0.0";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };

          openwebui = {
            Unit = {
              Description = "Open WebUI";
              After = [ "network-online.target" ];
              PartOf = [ "llama-stack.target" ];
            };
            Service = {
              Type = "simple";
              Environment = "DATA_DIR=${config.home.homeDirectory}/Applications/open-webui";
              ExecStart = "${pkgs.open-webui}/bin/open-webui serve";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
        };

        systemd.user.targets.llama-stack = {
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
        };
      };
  };
}
