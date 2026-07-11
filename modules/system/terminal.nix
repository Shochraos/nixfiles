{
  aspects.home.terminal =
    { ... }:
    {
      programs.ghostty = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          background = "000000";
          background-opacity = 0.5;
          background-blur = true;
          font-family = "OverpassM Nerd Font Mono";
          font-size = 12;
        };
      };
    };
}
