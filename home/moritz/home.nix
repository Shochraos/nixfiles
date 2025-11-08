
{ pkgs, ...}:

{
  home.username = "moritz";
  home.homeDirectory = "/home/moritz";
  home.stateVersion = "25.05";

  fonts.fontconfig.enable = true;

  imports = [
    ./modules/fonts.nix
    ./modules/fish.nix
    ./modules/terminal.nix
    ./modules/ssh.nix
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
}
