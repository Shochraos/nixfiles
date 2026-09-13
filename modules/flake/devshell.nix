{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          config.treefmt.build.wrapper
          pkgs.nixd
          pkgs.nixfmt
          pkgs.nix-unit
          pkgs.shellcheck
          pkgs.sops
          pkgs.ssh-to-age
        ]
        ++ config.pre-commit.settings.enabledPackages;

        shellHook = config.pre-commit.shellHook;

        env.NIX_PATH = "nixpkgs=${pkgs.path}";
      };
    };
}
