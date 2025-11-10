{ pkgs, ...}:
{
  home.username = "shochraos";
  home.homeDirectory = "/home/shochraos";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    MANGOHUD = "1";

  };

  imports = [
    ./modules/fonts.nix
    ./modules/fish.nix
    ./modules/terminal.nix
    ./modules/ssh.nix
    ./modules/git.nix
    ./modules/mangohud.nix
    ./modules/mpv.nix
    ./modules/dotdesktop.nix
  ];
}
