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

  testKeybindsRejectsBareString = {
    expr =
      (evalHost {
        host.hyprland.keybinds = [ "SUPER+Q" ];
      }).config.host.hyprland.keybinds;
    expectedError.msg = "not of type";
  };

  testBitdepthRejectsNine = {
    expr =
      (evalHost {
        host.outputs."DP-1".bitdepth = 9;
      }).config.host.outputs."DP-1".bitdepth;
    expectedError.msg = "is not of type";
  };
}
