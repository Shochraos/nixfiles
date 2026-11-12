{
  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      hooks = config.pre-commit.settings;
      runner = pkgs.writeShellScript "nixfiles-pre-commit" ''
        export PATH=${lib.makeBinPath ([ hooks.gitPackage ] ++ hooks.enabledPackages)}:$PATH
        exec ${lib.getExe hooks.package} hook-impl \
          --config ${hooks.configFile} --hook-type pre-commit \
          --hook-dir "$(${lib.getExe hooks.gitPackage} rev-parse --git-path hooks)" -- "$@"
      '';
      dispatcher = pkgs.writeText "nixfiles-shared-pre-commit" ''
        #!/bin/sh
        setup_required() {
          printf '%s\n' 'nixfiles: local pre-commit runner unavailable; enter nix develop in this checkout on this client, then retry Git.' >&2
        }
        root=$(git rev-parse --show-toplevel) || exit 1
        project_key=$(printf '%s' "$root" | sha256sum) || exit 1
        runner="''${XDG_STATE_HOME:-$HOME/.local/state}/nixfiles-hooks/''${project_key%% *}/runner"
        if [ ! -x "$runner" ]; then
          setup_required
          exit 1
        fi
        "$runner" "$@"
        status=$?
        if [ "$status" -eq 126 ] || [ "$status" -eq 127 ]; then
          setup_required
        fi
        exit "$status"
      '';
      legacyHook = pkgs.writeText "nixfiles-legacy-pre-commit" ''
        INSTALL_PYTHON=/nix/store/PACKAGE/bin/python
        ARGS=(hook-impl --config=.pre-commit-config.yaml --hook-type=pre-commit)
        HERE="$(cd "$(dirname "$0")" && pwd)"
        ARGS+=(--hook-dir "$HERE" -- "$@")
        exec /nix/store/PACKAGE/bin/pre-commit "''${ARGS[@]}"
      '';
      bootstrap = pkgs.writeShellApplication {
        name = "nixfiles-hooks-setup";
        runtimeInputs = [
          hooks.gitPackage
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.nix
          pkgs.util-linux
        ];
        text = ''
          if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
            printf '%s\n' 'nixfiles: no Git worktree found; skipping hook setup.' >&2
            exit 0
          fi
          cd "$root"
          hooks_status=0
          hooks_path=$(git config --get core.hooksPath) || hooks_status=$?
          if [[ "$hooks_status" -gt 1 ]]; then
            printf '%s\n' 'nixfiles: unable to read core.hooksPath; hook setup stopped.' >&2
            exit "$hooks_status"
          fi
          if [[ "$hooks_status" -eq 0 && "$hooks_path" != .git/hooks ]]; then
            printf '%s\n' 'nixfiles: refusing custom core.hooksPath; keep your hook setup or explicitly reconcile it before entering nix develop.' >&2
            exit 1
          fi
          hook=$(git rev-parse --git-path hooks/pre-commit)
          mkdir -p -- "$(dirname "$hook")"
          shared_lock="$(dirname "$hook")/.nixfiles-pre-commit.lock"
          if [[ -L "$shared_lock" || ( -e "$shared_lock" && ! -f "$shared_lock" ) ]]; then
            printf '%s\n' 'nixfiles: refusing a non-regular shared hook lock.' >&2
            exit 1
          fi
          exec 8>>"$shared_lock"
          flock -x 8
          if [[ -e "$hook" || -L "$hook" ]]; then
            if [[ -L "$hook" ]] || ! cmp -s -- ${dispatcher} "$hook"; then
              if [[ -L "$hook" ]] ||
                ! grep -qxF '# ID: 138fd403232d2ddd5efb44317e38bf03' "$hook" ||
                ! sed -E '/^#/d; /^$/d; s@/nix/store/[a-z0-9]{32}-[^/[:space:]]+@/nix/store/PACKAGE@g; s@/bin/python[0-9.]+$@/bin/python@' "$hook" | cmp -s -- ${legacyHook} -; then
                printf '%s\n' 'nixfiles: refusing to overwrite an unrecognized pre-commit hook; reconcile it explicitly, then enter nix develop again.' >&2
                exit 1
              fi
            fi
          fi
          project_key=$(printf '%s' "$root" | sha256sum)
          state="''${XDG_STATE_HOME:-$HOME/.local/state}/nixfiles-hooks/''${project_key%% *}"
          mkdir -p -- "$state/roots"
          if [[ -L "$state/setup.lock" || ( -e "$state/setup.lock" && ! -f "$state/setup.lock" ) ]]; then
            printf '%s\n' 'nixfiles: refusing a non-regular local setup lock.' >&2
            exit 1
          fi
          exec 9>>"$state/setup.lock"
          flock -x 9
          generation="$state/roots/${baseNameOf runner}"
          if [[ ! -L "$generation" ]] || [[ $(readlink "$generation") != ${runner} ]]; then
            nix-store --add-root "$generation" --indirect --realise ${runner} >/dev/null
          fi
          temporary=
          trap '[[ -z "$temporary" ]] || rm -f -- "$temporary"' EXIT
          if [[ ! -L "$state/runner" ]] || [[ $(readlink "$state/runner") != "$generation" ]]; then
            temporary=$(mktemp "$state/.runner.XXXXXXXX")
            ln -sf -- "$generation" "$temporary"
            mv -Tf -- "$temporary" "$state/runner"
            temporary=
          fi
          for old_root in "$state/roots/"*; do
            [[ "$old_root" == "$generation" ]] || rm -f -- "$old_root"
          done
          if ! cmp -s -- ${dispatcher} "$hook"; then
            temporary=$(mktemp "$(dirname "$hook")/.pre-commit.XXXXXXXX")
            cp -- ${dispatcher} "$temporary"
            chmod +x "$temporary"
            mv -Tf -- "$temporary" "$hook"
            temporary=
          elif [[ ! -x "$hook" ]]; then
            chmod +x "$hook"
          fi
        '';
      };
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          config.treefmt.build.wrapper
          hooks.package
          pkgs.actionlint
          pkgs.deadnix
          pkgs.nix-init
          pkgs.nixd
          pkgs.nixfmt
          pkgs.python3
          pkgs.ripgrep
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.sops
          pkgs.ssh-to-age
          pkgs.statix
        ]
        ++ config.pre-commit.settings.enabledPackages;

        shellHook = ''
          ${lib.getExe bootstrap}
        '';

        env.NIX_PATH = "nixpkgs=${pkgs.path}";
      };
    };
}
