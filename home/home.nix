{ lib, userName, isAzazel, ... }:
{
  # Username, Paths and Variables
  home =
  {
    username = "${userName}";
    homeDirectory = "/home/${userName}";
    stateVersion = "25.05";
    sessionVariables = lib.mkIf isAzazel
    {
      MANGOHUD = "1";
    };
  };

  # Imports
  imports =
  [
    # Import plasma-manager
    ./plasma/plasma.nix
    
    # General imports
    ./modules/fonts.nix
    ./modules/fish.nix
    ./modules/terminal.nix
    ./modules/ssh.nix
    ./modules/git.nix
    ./modules/packages.nix
    ./modules/starship.nix
    ./modules/zed.nix
  ]
  # Azazel exclusive imports
  ++ lib.optionals isAzazel
  [
    ./modules/mangohud.nix
    ./modules/mpv.nix
    ./modules/dotdesktop.nix
  ];
}
