{ pkgs, lib, config, systemName, ... }:
{
  programs.fish =
  {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      direnv hook fish | source
    '';

    shellAliases =
    {
      ls = "eza -1 -h -l --icons --no-user --group-directories-first -F $argv";
      la = "eza -1 -h -l --icons -a --no-user --group-directories-first -F $argv";
      lr = "eza -1 -h -l --icons -a -R --no-user --group-directories-first -F $argv";
      nix-shell = "nix-your-shell fish nix-shell -- $argv";
      nix-develop = "nix-your-shell fish nix-develop -- $argv";

      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/nixfiles#${systemName}";
    };

    functions =
    {
      denv =
      {
        body = ''
          if test (count $argv) -eq 0
              echo "Usage: denv <package1> <package2> ..."
              return 1
          end

          set packages (string join " " $argv)

          echo "{pkgs ? import <nixpkgs> {}}:" > shell.nix
          echo "" >> shell.nix
          echo "pkgs.mkShell {" >> shell.nix
          echo "    name = \"$packages\";" >> shell.nix  # Add the name field
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
  programs.direnv =
  {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };
}
