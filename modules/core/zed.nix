{
  pkgs,
  username,
  systemname,
  ...
}:
{
  programs.nix-ld.enable = true;
  environment.systemPackages = [ pkgs.nixfmt ];

  home-manager.users.${username} = {
    programs.zed-editor = {
      enable = true;
      extensions = [ "nix" ];
      extraPackages = with pkgs; [ nixd ];
      userSettings = {
        theme = {
          mode = "system";
          light = "DankShell Dark";
          dark = "DankShell Dark";
        };
        lsp = {
          nixd = {
            settings = {
              formatting = {
                command = [ "nixfmt" ];
              };
              nixpkgs = {
                expr = "import (builtins.getFlake \"/home/${username}/nixfiles\").inputs.nixpkgs";
              };
              options = {
                nixos = {
                  expr = "(builtins.getFlake \"/home/${username}/nixfiles\").nixosConfigurations.${systemname}.options";
                };
                home-manager = {
                  expr = "(builtins.getFlake \"/home/${username}/nixfiles\").nixosConfigurations.${systemname}.options.home-manager.users.type.getSubOptions []";
                };
              };
            };
          };
        };

        auto_update = false;
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        load_direnv = "shell_hook";
        base_keymap = "VSCode";

        vim_mode = false;
        autosave = {
          after_delay = {
            milliseconds = 1000;
          };
        };

        show_whitespaces = "all";

        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
            tab_size = 2;
          };

          Python = {
            language_servers = [
              "ty"
              "!basedpyright"
            ];
            code_actions_on_format = {
              "source.organizeImports.ruff" = true;
            };
            formatter = {
              language_server = {
                name = "ruff";
              };
            };
          };
        };
      };
    };
  };
}
