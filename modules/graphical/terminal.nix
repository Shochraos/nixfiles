{ config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.terminal.provides.to-users.homeManager =
    { osConfig, pkgs, ... }:
    {
      home.packages = [ pkgs.libnotify ];

      programs.ghostty = {
        enable = true;
        settings = {
          background = "000000";
          background-opacity = 0.7;
          background-blur = true;
          font-family = osConfig.stylix.fonts.monospace.name;
          font-size = osConfig.stylix.fonts.sizes.terminal;
        };
      };

      programs.kitty = {
        enable = true;

        font = {
          name = "family='${osConfig.stylix.fonts.monospace.name}' features='+calt +liga +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08 +ss09'";
          size = osConfig.stylix.fonts.sizes.terminal;
        };

        extraConfig = builtins.readFile assets.kittyConf;
        shellIntegration.enableBashIntegration = true;
      };
    };
}
