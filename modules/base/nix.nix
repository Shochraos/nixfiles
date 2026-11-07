{ config, ... }:
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
  den.aspects.nix = _: {
    nixos = {
      nixpkgs.overlays = [ sphinxHookOverlay ];

      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        settings.download-buffer-size = 524288000;
        settings.sync-before-registering = true;
        settings.auto-optimise-store = true;

        channel.enable = false;
      };

      programs.nh.clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 10";
      };
    };

  };
}
