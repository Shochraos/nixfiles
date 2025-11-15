{ pkgs, isAzazel, ... }:
{
  programs.ghostty =
  {
      enable = true;
      enableFishIntegration = true;
      settings =
      {
        # Appearance
        background = "000000";
        background-opacity = 0.2;
        background-blur = true;

        # Font
        font-family = "Fira Code Nerd Font";

        # Window size
        window-height = if isAzazel then 50 else 25 ;
        window-width  = if isAzazel then 150 else 80;
      };
  };
}