{
  den.aspects.terminal.provides.to-users.homeManager =
    { osConfig, ... }:
    {
      programs.ghostty = {
        enable = true;
        settings = {
          background = "000000";
          background-opacity = 0.5;
          background-blur = true;
          font-family = osConfig.stylix.fonts.monospace.name;
          font-size = osConfig.stylix.fonts.sizes.terminal;
        };
      };
    };
}
