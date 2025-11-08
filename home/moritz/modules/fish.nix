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
        body = "ls -alR";
      };
      rebuild = {
        body = "sudo nixos-rebuild switch --flake ~/NixOS-Config#azazel";
      };
      nix-shell = {
        body = "nix-your-shell fish nix-shell -- $argv";
      };
    };
  };

  programs.starship = {
    enable = true;
    settings = pkgs.lib.importTOML ../../../configs/starship/starship.toml;
  };
}
