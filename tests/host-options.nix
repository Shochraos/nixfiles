{ lib, optionsPath }:
let
  hostOptions =
    (import optionsPath {
      den = {
        default = { };
        aspects = { };
      };
      inherit lib;
    }).den.aspects.hostOptions;

  evalHost =
    extra:
    lib.evalModules {
      modules = [
        (hostOptions {
          host = {
            name = "Probe";
          };
          user = {
            name = "u";
          };
        }).nixos
        {
          options.users.users = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options.home = lib.mkOption {
                  type = lib.types.str;
                };
              }
            );
            default = { };
          };
        }
        {
          users.users.u.home = "/home/u";
          host.flakeDir = "/probe";
        }
        extra
      ];
    };
in
{
  testSshKeyDefaultResolvesEntityArgs = {
    expr = (evalHost { }).config.host.sshKey;
    expected = "/home/u/.ssh/probe";
  };

  testKeybindsRejectAMistypedArgsKey = {
    expr =
      (evalHost {
        host.hyprland.keybinds = [ { _arg = [ "SUPER + X" ]; } ];
      }).config.host.hyprland.keybinds;
    expectedError.msg = "_arg";
  };

  testKeybindsCarryTheirArgsUnchanged = {
    expr =
      (evalHost {
        host.hyprland.keybinds = [
          {
            _args = [
              "SUPER + X"
              "noop"
            ];
          }
        ];
      }).config.host.hyprland.keybinds;
    expected = [
      {
        _args = [
          "SUPER + X"
          "noop"
        ];
      }
    ];
  };

  testMatugenTemplatesRejectAMisspelledKey = {
    expr =
      (evalHost {
        host.matugen.templates.x = {
          input_paht = "/tmp/template";
          output_path = "~/out";
        };
      }).config.host.matugen.templates;
    expectedError.msg = "input_paht";
  };

  testMatugenTemplatesCarryBothFields = {
    expr =
      (evalHost {
        host.matugen.templates.x = {
          input_path = "/tmp/template";
          output_path = "~/out";
        };
      }).config.host.matugen.templates;
    expected = {
      x = {
        input_path = "/tmp/template";
        output_path = "~/out";
      };
    };
  };
}
