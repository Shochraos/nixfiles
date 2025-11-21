{ ... }:
{
  programs.plasma =
  {
    windows =
    {
      allowWindowsToRememberPositions = false;
    };

    kwin.effects =
    {
      blur =
      {
        enable = true;
        strength = 15;
        noiseStrength = 6;
      };

      translucency.enable = false;

      desktopSwitching =
      {
        navigationWrapping = true;
        animation = "slide";
      };
    };

    kwin =
    {
      virtualDesktops =
      {
        names = [ "Desktop_1" "Desktop_2" "Desktop_3" ];
        number = 3;
        rows = 1;
      };
    };
  };
}