{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.nixd
          pkgs.nixfmt
          pkgs.shellcheck
          pkgs.sops
          pkgs.ssh-to-age
        ];

        env.NIX_PATH = "nixpkgs=${pkgs.path}";
      };
    };
}
