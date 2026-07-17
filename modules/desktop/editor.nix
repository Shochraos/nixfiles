{
  den.aspects.editor =
    { host, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          programs.nix-ld.enable = true;
          environment.systemPackages = [ pkgs.nixfmt ];
        };

      provides.to-users.homeManager =
        {
          config,
          osConfig,
          pkgs,
          ...
        }:
        {
          xdg.autostart = {
            entries = [
              "${config.programs.zed-editor.package}/share/applications/dev.zed.Zed.desktop"
            ];
          };
          programs.zed-editor = {
            enable = true;
            extensions = [
              "nix"
              "csv"
            ];
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
                      expr = "import (builtins.getFlake \"${osConfig.host.flakeDir}\").inputs.nixpkgs";
                    };
                    options = {
                      nixos = {
                        expr = "(builtins.getFlake \"${osConfig.host.flakeDir}\").nixosConfigurations.${host.name}.options";
                      };
                      home-manager = {
                        expr = "(builtins.getFlake \"${osConfig.host.flakeDir}\").nixosConfigurations.${host.name}.options.home-manager.users.type.getSubOptions []";
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

              load_direnv = "direct";
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
    };
}
