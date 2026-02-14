{ pkgs, username, ... }:
{
  home-manager.users.${username} =
  {
    home.packages = with pkgs; 
    [
      libreoffice-qt-fresh
      pdfslicer
    ];
  };
}