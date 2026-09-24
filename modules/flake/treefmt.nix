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
        actionlint.enable = true;
        statix = {
          enable = true;
          disabled-lints = [ "repeated_keys" ];
        };
        deadnix = {
          enable = true;
          no-lambda-arg = true;
          no-lambda-pattern-names = true;
        };
      };

      settings.formatter.shellcheck.excludes = [ ".envrc" ];
    };
  };
}
