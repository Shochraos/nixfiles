{ inputs, ... }:
{
  den.aspects.nix =
    { user, ... }:
    {
      nixos = {
        nix = {
          settings.trusted-users = [
            "root"
            user.name
          ];

          settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
          settings.download-buffer-size = 524288000;
          settings.sync-before-registering = true;
          optimise.automatic = true;

          channel.enable = false;
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };

      provides.to-users.homeManager =
        { osConfig, pkgs, ... }:
        {
          imports = [ inputs.nix-index-database.homeModules.default ];

          programs.nix-index.enable = true;
          programs.nix-index-database.comma.enable = true;

          programs.nh = {
            enable = true;
            flake = osConfig.host.flakeDir;
            clean.enable = true;
            clean.extraArgs = "--keep-since 7d --keep 10";
          };

          programs.direnv = {
            enable = true;
            silent = true;
            nix-direnv.enable = true;
          };

          home.packages = with pkgs; [ nix-init ];
        };
    };
}
