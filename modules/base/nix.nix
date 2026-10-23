{ config, inputs, ... }:
let
  inherit (config) assets;

  sphinxHookOverlay = _final: prev: {
    python314 = prev.python314.override {
      packageOverrides = _self: _super: {
        sphinxHook = prev.makeSetupHook {
          name = "sphinx-hook";
          passthru.provides.setupHook = true;
          propagatedBuildInputs = [
            prev.python3Packages.sphinx
            prev.installShellFiles
          ];
          substitutions = {
            sphinxBuild = "${prev.python3Packages.sphinx}/bin/sphinx-build";
          };
        } assets.sphinxHookScript;
      };
    };
  };
in
{
  den.aspects.nix =
    { user, ... }:
    {
      nixos = {
        nixpkgs.overlays = [ sphinxHookOverlay ];

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
          settings.auto-optimise-store = true;

          channel.enable = false;
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };

      provides.to-users.homeManager =
        { osConfig, ... }:
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
        };
    };
}
