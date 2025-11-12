{ pkgs, lib, systemName, ... }:
let
  Azazel = lib.mkIf (systemName == "Azazel");
in
{
  home =
  {
    username = "shochraos";
    homeDirectory = "/home/shochraos";
    stateVersion = "25.05";
    sessionVariables = Azazel {
      MANGOHUD = "1";
    };
  };

  imports =
  [
    ./modules/fonts.nix
    ./modules/fish.nix
    ./modules/terminal.nix
    ./modules/ssh.nix
    ./modules/git.nix
    ./modules/packages.nix
  ]
  ++ lib.optionals (systemName == "Azazel")
  [
    ./modules/mangohud.nix
    ./modules/mpv.nix
    ./modules/dotdesktop.nix
  ];
}
