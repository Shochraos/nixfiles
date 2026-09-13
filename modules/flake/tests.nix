top@{ config, ... }:
let
  inherit (config) helpers tests;

  azazelHome =
    let
      homes = top.config.flake.nixosConfigurations.Azazel.config.home-manager.users;
      names = builtins.attrNames homes;
    in
    if builtins.length names == 1 then
      homes.${builtins.head names}
    else
      throw "check: expected exactly one home-manager user on Azazel, got ${toString (builtins.length names)}";
in
{
  perSystem =
    { lib, pkgs, ... }:
    let
      fromAzazel =
        name:
        lib.findFirst (
          p: (p.name or "") == name
        ) (throw "check: ${name} is not in Azazel's home.packages") azazelHome.home.packages;
    in
    {
      checks.unit-tests =
        pkgs.runCommandLocal "nix-unit-suite"
          {
            nativeBuildInputs = [ pkgs.nix-unit ];
          }
          ''
            export HOME="$TMPDIR"
            nix-unit --eval-store "$HOME" \
              --argstr nixpkgsPath ${pkgs.path} \
              --argstr optionsPath ${tests.options} \
              --argstr displayPath ${helpers.display} \
              --argstr aiPath ${tests.ai} \
              --argstr audioPath ${helpers.audio} \
              ${tests.dir}/default.nix
            touch $out
          '';

      checks."scripts/hdr-set" = pkgs.runCommandLocal "check-hdr-set" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        PATH="${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
          ]
        }:${fromAzazel "hdr-set"}/bin:${fromAzazel "hdr"}/bin:''${PATH}" \
          ${pkgs.bash}/bin/bash ${tests.scripts}/hdr-set.sh
        touch $out
      '';

      checks."scripts/eq" = pkgs.runCommandLocal "check-eq" { } ''
        export HOME="$TMPDIR/home"
        export XDG_STATE_HOME="$TMPDIR/state"
        export XDG_RUNTIME_DIR="$TMPDIR/run"
        mkdir -p "$HOME" "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"
        PATH="${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
            pkgs.systemd
          ]
        }:${fromAzazel "eq"}/bin:''${PATH}" \
          ${pkgs.bash}/bin/bash ${tests.scripts}/eq.sh
        touch $out
      '';
    };
}
