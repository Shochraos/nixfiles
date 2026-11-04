{ den, config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.mp3tag = {
    includes = [ (den.batteries.unfree [ "mp3tag" ]) ];

    provides.to-users.homeManager =
      { pkgs, ... }:
      let
        mp3tag = pkgs.callPackage config.packageSources.mp3tag { };
      in
      {
        home.packages = [ mp3tag ];

        xdg.desktopEntries = {
          mp3tag = {
            name = "MP3Tag";
            exec = "mp3tag";
            terminal = false;
            startupNotify = false;
            icon = "${assets.mp3tagIcon}";
          };
        };
      };
  };
}
