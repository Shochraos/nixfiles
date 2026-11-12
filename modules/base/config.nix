{ inputs, ... }:
{
  den.aspects.base = {
    provides.to-users.nixos = _: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };

    provides.to-users.homeManager =
      { osConfig, pkgs, ... }:
      {
        imports = [ inputs.nix-index-database.homeModules.default ];

        systemd.user.servicesStartTimeoutMs = 16 * 60 * 1000;

        programs.nix-index.enable = true;
        programs.nix-index-database.comma.enable = true;
        programs.nh = {
          enable = true;
          flake = "github:Shochraos/nixfiles/main";
        };
        programs.direnv = {
          enable = true;
          silent = true;
          nix-direnv.enable = true;
          stdlib = ''
            direnv_layout_dir() {
              if [[ -n ''${direnv_layout_dir:-} ]]; then
                printf '%s\n' "$direnv_layout_dir"
              else
                case "$PWD" in
                  /mnt/astaroth/projects|/mnt/astaroth/projects/*)
                    local project_key
                    project_key=$(printf '%s' "$PWD" | ${pkgs.coreutils}/bin/sha256sum)
                    printf '%s/direnv/layouts/%s\n' "''${XDG_CACHE_HOME:-$HOME/.cache}" "''${project_key%% *}"
                    ;;
                  *) printf '%s/.direnv\n' "$PWD" ;;
                esac
              fi
            }
          '';
        };

        home.packages = [
          pkgs.sops
          pkgs.ssh-to-age
        ];
        home.sessionVariables.SOPS_AGE_KEY_CMD = "ssh-to-age -private-key -i ${osConfig.host.sshKey}";
      };
  };
}
