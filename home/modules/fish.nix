{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      direnv hook fish | source
    '';

    functions = {
      la = {
        body = ''ls -al'';
      };
      lr = {
        body = ''ls -alR'';
      };
      rebuild = {
        body = ''sudo nixos-rebuild switch --flake ~/NixOS-Config#azazel'';
      };
      nix-shell = {
        body = ''nix-your-shell fish nix-shell -- $argv'';
      };
      nix-develop = {
        body = ''nix-your-shell fish nix-develop -- $argv'';
      };

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
          echo "    packages = with pkgs; [ $packages ];" >> shell.nix
          echo "}" >> shell.nix

          echo "use nix" > .envrc

          direnv allow

          echo "Created shell.nix and .envrc for packages: $packages"
          '';
        };
    };
  };

  # Direnv
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };
}
