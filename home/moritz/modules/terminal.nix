{ pkgs, ... }:
{
  home.packages = [ pkgs.ghostty ];

    home.file.".config/ghostty/config".text = ''
      background = 000000
      background-opacity = 0.2
      background-blur = true

      font-family = "Fira Code Nerd Font"

      window-height = 50
      window-width = 150
    '';
}