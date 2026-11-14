{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      pre-commit.check.enable = false;
      pre-commit.settings.install.enable = false;

      pre-commit.settings.hooks.treefmt = {
        enable = true;
        always_run = true;
        entry = "${config.pre-commit.settings.hooks.treefmt.packageOverrides.treefmt}/bin/treefmt --fail-on-change --no-cache";
        packageOverrides.treefmt = (import inputs.treefmt-nix).mkWrapper pkgs {
          inherit (config.treefmt) projectRootFile;
          enableDefaultExcludes = false;
          settings = (builtins.removeAttrs config.treefmt.settings [ "global" ]) // {
            formatter = config.treefmt.settings.formatter // {
              nixfmt = config.treefmt.settings.formatter.nixfmt // {
                options = config.treefmt.settings.formatter.nixfmt.options ++ [ "--check" ];
              };
              deadnix = config.treefmt.settings.formatter.deadnix // {
                options = map (
                  option: if option == "--edit" then "--fail" else option
                ) config.treefmt.settings.formatter.deadnix.options;
              };
              shfmt = config.treefmt.settings.formatter.shfmt // {
                options = map (
                  option: if option == "-w" then "--diff" else option
                ) config.treefmt.settings.formatter.shfmt.options;
              };
              statix = config.treefmt.settings.formatter.statix // {
                command = lib.getExe' (pkgs.writeShellScriptBin "statix-check" ''
                  set -e
                  for file in "$@"; do
                    ${lib.getExe config.treefmt.programs.statix.package} check --config ${
                      (pkgs.formats.toml { }).generate "statix.toml" {
                        disabled = config.treefmt.programs.statix.disabled-lints;
                      }
                    } "$file"
                  done
                '') "statix-check";
              };
            };
          };
        };
      };

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
