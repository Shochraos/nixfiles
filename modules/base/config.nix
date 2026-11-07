{ inputs, ... }:
{
  den.aspects.base = {
    provides.to-users.nixos =
      {
        lib,
        user,
        utils,
        ...
      }:
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
        systemd.services."home-manager-${utils.escapeSystemdPath user.name}".serviceConfig.TimeoutStartSec =
          lib.mkForce "17min";
      };

    provides.to-users.homeManager =
      { osConfig, pkgs, ... }:
      {
        imports = [ inputs.nix-index-database.homeModules.default ];

        systemd.user.servicesStartTimeoutMs = 16 * 60 * 1000;

        programs.nix-index.enable = true;
        programs.nix-index-database.comma.enable = true;
        programs.nh = {
          enable = true;
          flake = osConfig.host.flakeDir;
        };
        programs.direnv = {
          enable = true;
          silent = true;
          nix-direnv.enable = true;
        };

        home.packages = [
          pkgs.sops
          pkgs.ssh-to-age
        ];
        home.sessionVariables.SOPS_AGE_KEY_CMD = "ssh-to-age -private-key -i ${osConfig.host.sshKey}";
      };
  };
}
