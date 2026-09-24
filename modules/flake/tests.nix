top@{ config, inputs, ... }:
let
  inherit (config) tests;

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
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { lib, pkgs, ... }:
    let
      fromAzazel =
        name:
        lib.findFirst (
          p: (p.name or "") == name
        ) (throw "check: ${name} is not in Azazel's home.packages") azazelHome.home.packages;

      unitTests = pkgs.writeShellApplication {
        name = "unit-tests";
        runtimeInputs = [ pkgs.nix-unit ];
        text = ''
          nix-unit --eval-store "''${TMPDIR:-/tmp}" \
            --argstr nixpkgsPath ${pkgs.path} \
            --argstr optionsPath ${tests.options} \
            --argstr aiPath ${tests.ai} \
            --argstr audioPath ${tests.audioAspect} \
            --argstr dankshellPath ${tests.dankshellAspect} \
            --argstr hdrPath ${tests.hdrAspect} \
            --argstr hyprlandConfigPath ${tests.hyprlandConfigAspect} \
            --argstr hyprlandRulesPath ${tests.hyprlandRulesAspect} \
            --argstr streamingPath ${tests.streamingAspect} \
            ${tests.dir}/default.nix
        '';
      };
    in
    {
      packages.unit-tests = unitTests;

      checks.unit-tests = pkgs.runCommandLocal "nix-unit-suite" { } ''
        ${lib.getExe unitTests}
        touch $out
      '';

      checks."hermes-soul" = pkgs.runCommandLocal "check-hermes-soul" { } ''
        export LC_ALL=C
        soul=${config.assets.hermesSoul}
        payloads="${lib.concatStringsSep " " azazelHome.services.hermes-agent.settings.skills.external_dirs}"

        for payload in ''${payloads}; do
          for skill in "$payload"/*/; do
            [ -f "$skill/SKILL.md" ] || continue
            sed -n 's/^name:[[:space:]]*//p' "$skill/SKILL.md" | sed -n 1p
          done
        done | sort -u > "$TMPDIR/installed"

        sed -n '/^# Skills$/,/^# /{
          s/^- .*`\([a-z0-9-][a-z0-9-]*\)`$/\1/p
        }' "$soul" | sort -u > "$TMPDIR/routed"

        if [ ! -s "$TMPDIR/routed" ]; then
          echo "hermes-soul: no routing bullets found — the 'Skills' section of SOUL.md must list them one per line, each ending in the skill name in backticks:" >&2
          echo '  - <when to use it>: `<skill-name>`' >&2
          exit 1
        fi

        unknown=$(comm -23 "$TMPDIR/routed" "$TMPDIR/installed")
        if [ -n "$unknown" ]; then
          echo "hermes-soul: routed skills that no installed payload provides — a renamed or removed skill leaves its line silently dead:" >&2
          echo "$unknown" >&2
          exit 1
        fi

        unrouted=$(comm -13 "$TMPDIR/routed" "$TMPDIR/installed")
        if [ -n "$unrouted" ]; then
          echo "hermes-soul: installed skills with no routing bullet — add one line each to the 'Skills' section:" >&2
          echo "$unrouted" >&2
          exit 1
        fi

        touch $out
      '';

      pre-commit.settings.hooks = {
        treefmt = {
          enable = true;
          always_run = true;
        };

        unit-tests = {
          enable = true;
          name = "nix-unit";
          entry = lib.getExe unitTests;
          pass_filenames = false;
          always_run = true;
        };
      };

      checks."scripts/hdr-set" = pkgs.runCommandLocal "check-hdr-set" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        export SHADOW_LIB="${lib.getLib pkgs.glibc}/lib/libm.so.6"
        PATH="${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.jq
            pkgs.util-linux
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
          ]
        }:${fromAzazel "eq"}/bin:''${PATH}" \
          ${pkgs.bash}/bin/bash ${tests.scripts}/eq.sh
        touch $out
      '';
      checks."scripts/streaming" = pkgs.runCommandLocal "check-streaming" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        export SHADOW_LIB="${lib.getLib pkgs.glibc}/lib/libm.so.6"
        PATH="${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gamescope
            pkgs.jq
            pkgs.util-linux
          ]
        }:${fromAzazel "frame"}/bin:${fromAzazel "frame-display"}/bin:${fromAzazel "deck"}/bin:${fromAzazel "deck-display"}/bin:${fromAzazel "streaming-displays"}/bin:''${PATH}" \
          ${pkgs.bash}/bin/bash ${tests.scripts}/streaming.sh
        touch $out
      '';

      checks."scripts/backup" = pkgs.runCommandLocal "check-backup" { } ''
        export HOME="$TMPDIR/home"
        export XDG_RUNTIME_DIR="$TMPDIR/run"
        mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
        PATH="${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.gawk
            pkgs.gnugrep
            pkgs.util-linux
          ]
        }:${fromAzazel "backup"}/bin:''${PATH}" \
          ${pkgs.bash}/bin/bash ${tests.scripts}/backup.sh
        touch $out
      '';

      checks."scripts/jellyfin-settings" = pkgs.runCommandLocal "check-jellyfin-settings" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        PATH="${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.jq
          ]
        }:${fromAzazel "jellyfin-settings"}/bin:''${PATH}" \
          ${pkgs.bash}/bin/bash ${tests.scripts}/jellyfin-settings.sh
        touch $out
      '';

    };
}
