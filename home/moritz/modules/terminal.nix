{ pkgs, ... }:
{
  home.packages = [ pkgs.ghostty ];

    home.file.".config/ghostty/config".text = ''
      background = 1e1e1e
      background-opacity = 0.6
      background-blur = true

      font-family = "Jetbrains Mono"

      window-height = 50
      window-width = 150
    '';
}