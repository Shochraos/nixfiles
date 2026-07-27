{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        nixfmt.enable = true;
        shfmt = {
          enable = true;
          indent_size = 2;
        };
        shellcheck.enable = true;
      };

      settings.formatter.shellcheck.excludes = [ ".envrc" ];
    };
  };
}
