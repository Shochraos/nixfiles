
{ pkgs, ...}:

{
  home.username = "shochraos";
  home.homeDirectory = "/home/shochraos";
  home.stateVersion = "25.05";

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    MANGOHUD = "1";

  };

  imports = [
    ./modules/fonts.nix
    ./modules/fish.nix
    ./modules/terminal.nix
    ./modules/ssh.nix
    ./modules/mangohud.nix
    ./modules/dotdesktop.nix
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
}
