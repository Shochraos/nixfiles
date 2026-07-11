{
  aspects.nixos.nix =
  { username, ... }:
  {
    nix = {
      settings.trusted-users = [ "root" "${username}" ];

      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      settings.download-buffer-size = 524288000;
      settings.auto-optimise-store = true;
      

      channel.enable = false;
    };

    nixpkgs.config = {
      allowUnfree = true;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };

  aspects.home.nix =
    {
      inputs,
      pkgs,
      username,
      ...
    }:
    {
      imports = [ inputs.nix-index-database.homeModules.default ];

      programs.nix-index = {
        enable = true;
        enableFishIntegration = true;
      };
      programs.nix-index-database.comma.enable = true;

      programs.nh = {
        enable = true;
        flake = "/home/${username}/Repositories/nixfiles";
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 10";
      };

      programs.direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
      };

      programs.fish = {
        interactiveShellInit = ''
          direnv hook fish | source
        '';

        functions = {
          denv = {
            body = ''
              if test (count $argv) -eq 0
                  echo "Usage: denv <package1> <package2> ..."
                  return 1
              end

              set packages (string join " " $argv)

              echo "{pkgs ? import <nixpkgs> {}}:" > shell.nix
              echo "" >> shell.nix
              echo "pkgs.mkShell {" >> shell.nix
              echo "    name = \"$packages\";" >> shell.nix
              echo "    packages = with pkgs; [ $packages ];" >> shell.nix
              echo "}" >> shell.nix

              echo "use nix" > .envrc

              direnv allow

              echo "Created shell.nix and .envrc for packages: $packages"
            '';
          };
        };
      };

      home.packages = with pkgs; [
        nix-init
        nix-your-shell
      ];
    };
}
